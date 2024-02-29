class CsgoempireService < ApplicationService
  include HTTParty
  
  BASE_URL = CSGO_EMPIRE_BASE_URL

  def initialize(current_user)
    @current_user = current_user
    @active_steam_account = current_user.active_steam_account
    @headers_csgo_empire = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
    @headers_waxpeer = { api: @active_steam_account&.waxpeer_api_key }
    reset_proxy
    add_proxy(@active_steam_account) if @active_steam_account&.proxy.present?
  end

  def headers(api_key, steam_account)
    reset_proxy
    add_proxy(steam_account) if steam_account&.proxy.present?
    { 'Authorization' => "Bearer #{api_key}" }
  end

  def fetch_balance
    if @active_steam_account.present?
      return if csgoempire_key_not_found?
      begin
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: @headers_csgo_empire)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end

      if response['success'] == false
        report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
        return []
      else
        response_data = response['user'] ? response['user']['balance'].to_f / 100 : 0
      end
    else
      response_data = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: headers(steam_account&.csgoempire_api_key, steam_account))
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
        response = {
          account_id: steam_account.id,
          balance: response['user']['balance'].to_f / 100
        }
        response_data << response
      end
    end
    response_data
  end

  def socket_data(data)
    TradeStatusJob.perform_async(data)
  end

  def items_bid_history
    response = []
    if @active_steam_account.present?
      return [] if csgoempire_key_not_found?
      begin
        res = self.class.get(BASE_URL + '/trading/user/auctions', headers: @headers_csgo_empire)
      rescue => e
        response = [{ success: "false" }]
      end
      if res['success'] == false
        report_api_error(res, [self&.class&.name, __method__.to_s])
        response = [{ success: "false" }]
      else
        response = res['active_auctions'] if res['active_auctions'].present?
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          res = self.class.get(BASE_URL + '/trading/user/auctions', headers: headers(steam_account.csgoempire_api_key, steam_account))
          if res['success'] == true
            if res['active_auctions'].present?
              res['active_auctions'].each do |auctions|
                response << auctions
              end
            end
          else
            response = [{ success: "false" }]
            break
          end
        rescue => e
          response = [{ success: "false" }]
        end
      end
    end
    response
  end

  def self.fetch_user_data(steam_account)
    headers = { 'Authorization' => "Bearer #{steam_account&.csgoempire_api_key}" }
    begin
      response = self.get(BASE_URL + '/metadata/socket', headers: headers)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end
    if response['success'] == false
      report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
      return []
    else
      response
    end
  end

  def fetch_my_inventory
    if @active_steam_account.present?
      unless csgoempire_key_not_found?
        get_inventory_from_api("csgoempire", @steam_account)
      end
      unless waxpeer_api_key_not_found?
        get_inventory_from_api("waxpeer", @steam_account)
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        get_inventory_from_api("csgoempire", steam_account) unless steam_account&.csgoempire_api_key.blank?
        get_inventory_from_api("waxpeer", steam_account) unless steam_account&.waxpeer_api_key.blank?
      end
    end
  end

  def get_inventory_from_api(type, steam_account)
    begin
      case type
      when "csgoempire"
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: { 'Authorization' => "Bearer #{steam_account&.csgoempire_api_key}" })
        puts "Error in CSGOEmpire Service get_inventory_from_api csgoempire #{response["error"]}" if response["error"] 
        save_inventory(response, @active_steam_account, "csgoempire") if response['success'] == true
      when "waxpeer"
        response = self.class.get(WAXPEER_BASE_URL + '/get-my-inventory', query: { api: steam_account&.waxpeer_api_key })
        puts "Error in CSGOEmpire Service get_inventory_from_api waxpeer #{response["error"]}" if response["error"] 
        save_inventory(response, @active_steam_account, "waxpeer") if response['success'] == true
      else
        raise ArgumentError, "Invalid type of Market: #{type} in CSGO Service <get_inventory_from_api(type)>"
      end
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end
  end

  def save_inventory(res, steam_account, type)
    case type
    when "csgoempire"
      items_to_insert = []
      res['data']&.each do |item|
        inventory = Inventory.find_by(item_id: item['id'])
        price_empire_item = PriceEmpire.find_by(item_name: item['market_name'])
        unless inventory.present?
          if price_empire_item.present? && price_empire_item['buff_avg7'].present?
            item_price = price_empire_item['buff_avg7']['price'] < 0 ? 0 : (((price_empire_item['buff_avg7']['price'] * 0.95).to_f / 100) * 0.614).round(2)
          else
            item_price = item['market_value'] < 0 ? 0 : ((item['market_value'].to_f / 100) * 0.614).round(2)
          end
          items_to_insert << {
            item_id: item['id'],
            steam_id: steam_account&.steam_id,
            market_name: item['market_name'],
            market_price: item_price,
            tradable: item['tradable'],
            market_type: type
          }
        end
      end
    when "waxpeer"
      items_to_insert = []
      res["items"]&.each do |item|
        price_empire_item = PriceEmpire.find_by(item_name: item['market_name'])
        inventory = Inventory.find_by(item_id: item['item_id'])
        unless inventory.present?
          #ASK PRICE CALCULATION
          if price_empire_item.present?
            item_price = price_empire_item['buff_avg7']['price'] < 0 ? 0 : ((price_empire_item['buff_avg7']['price'] * 0.95)).round
          else
            item_price = item["steam_price"]["average"] < 0 ? 0 : item["steam_price"]["average"]
          end
          items_to_insert << {
            item_id: item["item_id"],
            steam_id: steam_account&.steam_id,
            market_name: item["name"],
            market_price: item_price,
            tradable: nil, #ASK
            market_type: type
          }
        end
      end
    else
      puts "Invalid market type for fetching inventory"
      return []
    end
    Inventory.insert_all(items_to_insert) unless items_to_insert.empty?
  end

  # def save_inventory(res, steam_account, type)
  #   case type
  #   when "csgoempire"
  #     save_csgo_empire_inventory(res, steam_account)
  #   when "waxpeer"
  #     save_waxpeer_inventory(res, steam_account)
  #   else
  #     puts "Invalid market type for fetching inventory"
  #     return []
  #   end
  # end


  # def save_csgo_empire_inventory(res, steam_account)
  #   items_to_insert = []
  
  #   res['data']&.each do |item|
  #     inventory = find_inventory_by_item_id(item['id'])
  #     price_empire_item = find_price_empire_by_item_name(item['market_name'])
  #     unless inventory.present?
  #       item_price = calculate_item_price(price_empire_item, item['market_value'])
  #       items_to_insert << build_inventory_hash(item['id'], steam_account&.steam_id, item['market_name'], item_price, item['tradable'], "csgoempire")
  #     end
  #   end
  
  #   insert_inventory(items_to_insert)
  # end

  # def save_waxpeer_inventory(res, steam_account)
  #   items_to_insert = []
  #   res["items"]&.each do |item|
  #     inventory = find_inventory_by_item_id(item['item_id'])
  #     price_empire_item = find_price_empire_by_item_name(item['market_name'])
  #     unless inventory.present?
  #       item_price = calculate_item_price(price_empire_item, item["steam_price"]["average"])
  #       items_to_insert << build_inventory_hash(item["item_id"], steam_account&.steam_id, item["name"], item_price, nil, "waxpeer")
  #     end
  #   end
  
  #   insert_inventory(items_to_insert)
  # end

  # def find_inventory_by_item_id(item_id)
  #   Inventory.find_by(item_id: item_id)
  # end
  
  # def find_price_empire_by_item_name(item_name)
  #   PriceEmpire.find_by(item_name: item_name)
  # end

  # def build_inventory_hash(item_id, steam_id, market_name, market_price, tradable, market_type)
  #   {
  #     item_id: item_id,
  #     steam_id: steam_id,
  #     market_name: market_name,
  #     market_price: market_price,
  #     tradable: tradable,
  #     market_type: market_type
  #   }
  # end
  
  # def insert_inventory(items_to_insert)
  #   Inventory.insert_all(items_to_insert) unless items_to_insert.empty?
  # end

  # def calculate_item_price(price_empire_item, market_value)
  #   return 0 if market_value < 0
  
  #   if price_empire_item.present?
  #     price = price_empire_item['buff_avg7']['price'] < 0 ? 0 : (((price_empire_item['buff_avg7']['price'] * 0.95).to_f / 100) * 0.614).round(2)
  #   else
  #     price = ((market_value.to_f / 100) * 0.614).round(2)
  #   end
  
  #   price
  # end

  def remove_item(deposit_id)
    begin
      response = self.class.get("#{BASE_URL}/trading/deposit/#{deposit_id}/cancel", headers: @headers_csgo_empire)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end

    if response['success'] == false
      return []
    else
      response
    end
  end

  def save_transaction(response, steam_account)
    return if steam_account.sold_item_job_id.present? &&
              !Sidekiq::Status::get_all(steam_account.sold_item_job_id).empty? &&
              !Sidekiq::Status::failed?(steam_account.sold_item_job_id) &&
              !Sidekiq::Status::complete?(steam_account.sold_item_job_id)

    return if response['data'].blank?

    job_id = SaveTransactionWorker.perform_async(response, steam_account.id, @headers_csgo_empire)
    steam_account.update(sold_item_job_id: job_id)
  end

  # def fetch_deposit_transactions
  #   if @active_steam_account.present?
  #     return if csgoempire_key_not_found?
  #     begin
  #       response = self.class.get("#{BASE_URL}/user/transactions", headers: @headers)
  #     rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
  #       return []
  #     end
  #     save_transaction(response, @active_steam_account)
  #   else
  #     @current_user.steam_accounts.each do |steam_account|
  #       next if steam_account&.csgoempire_api_key.blank?
  #       begin
  #         response = self.class.get("#{BASE_URL}/user/transactions", headers: headers(steam_account.csgoempire_api_key, steam_account))
  #       rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
  #         return []
  #       end
  #       save_transaction(response, steam_account)
  #     end
  #   end
  # end

  def csgoempire_key_not_found?
    @active_steam_account&.csgoempire_api_key.blank?
  end

  def waxpeer_api_key_not_found?
    @active_steam_account&.waxpeer_api_key.blank?
  end

  def add_proxy(steam_account)
    proxy = steam_account.proxy
    self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
  end
end
