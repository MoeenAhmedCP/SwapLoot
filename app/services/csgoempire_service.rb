class CsgoempireService < ApplicationService
  include HTTParty
  
  BASE_URL = CSGO_EMPIRE_BASE_URL 

  def initialize(current_user)
    @current_user = current_user
    @active_steam_account = current_user.active_steam_account
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end

  def headers(api_key)
    @headers = { 'Authorization' => "Bearer #{api_key}" }
  end

  def fetch_balance
    if @active_steam_account.present?
      return if csgoempire_key_not_found?
      begin
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: @headers)
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
          response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: headers(steam_account&.csgoempire_api_key))
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
        res = self.class.get(BASE_URL + '/trading/user/auctions', headers: @headers)
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
          res = self.class.get(BASE_URL + '/trading/user/auctions', headers: headers(steam_account.csgoempire_api_key))
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
      return if csgoempire_key_not_found?
      begin
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: @headers)
        save_inventory(response, @active_steam_account) if response['success'] == true
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers(steam_account.csgoempire_api_key))
          save_inventory(response, steam_account) if response['success'] == true
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
      end
    end
  end

  def save_inventory(res, steam_account)
    items_to_insert = []

    res['data']&.each do |item|
      inventory = Inventory.find_by(item_id: item['id'])
      unless inventory.present?
        item_price = item['market_value'] < 0 ? 0 : ((item['market_value'].to_f / 100) * 0.614).round(2)
        items_to_insert << {
          item_id: item['id'],
          steam_id: steam_account&.steam_id,
          market_name: item['market_name'],
          market_price: item_price,
          tradable: item['tradable']
        }
      end
    end
    Inventory.insert_all(items_to_insert) unless items_to_insert.empty?
  end

  def remove_item(deposit_id)
    begin
      response = self.class.get("#{BASE_URL}/trading/deposit/#{deposit_id}/cancel", headers: @headers)
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

    job_id = SaveTransactionWorker.perform_async(response, steam_account.id, @headers)
    steam_account.update(sold_item_job_id: job_id)
  end

  def fetch_deposit_transactions
    if @active_steam_account.present?
      return if csgoempire_key_not_found?
      begin
        response = self.class.get("#{BASE_URL}/user/transactions", headers: @headers)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end
      save_transaction(response, @active_steam_account)
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          response = self.class.get("#{BASE_URL}/user/transactions", headers: headers(steam_account.csgoempire_api_key))
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
        save_transaction(response, steam_account)
      end
    end
  end

  def csgoempire_key_not_found?
    @active_steam_account&.csgoempire_api_key.blank?
  end

end
