class MarketcsgoService < ApplicationService
  include HTTParty  

  def initialize(current_user)
    @active_steam_account = current_user.active_steam_account
    @current_user = current_user
    @params = {
      key: "#{@active_steam_account&.market_csgo_api_key}"
    }
    @active_trade_query = {
      key: "#{@active_steam_account&.market_csgo_api_key}",
      extended: 1
    }
    reset_proxy
    add_proxy(@active_steam_account) if @active_steam_account&.proxy.present?
  end

  def site_params(steam_account)
    { key: "#{steam_account&.market_csgo_api_key}" }
  end

  def site_active_trade_params(steam_account)
    { key: "#{steam_account&.market_csgo_api_key}", extended: 1 }
  end

  def fetch_balance
    if @active_steam_account.present?
      return if market_csgo_api_key_not_found?

      res = self.class.get(MARKET_CSGO_BASE_URL + '/get-money', query: @params)
      if res['success'] == false
        report_api_error(res, [self&.class&.name, __method__.to_s])
      else
        res['money']
      end
    else
      response_data = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.market_csgo_api_key.blank?
        
        response = self.class.get(MARKET_CSGO_BASE_URL + '/get-money', query: site_params(steam_account))
        response_hash = {
          account_id: steam_account.id,
          balance: response['money']
        }
        response_data << response_hash
      end
      response_data
    end
  end

  def fetch_my_inventory
    if @active_steam_account.present?
      return if market_csgo_api_key_not_found?
      begin
        response = self.class.get(MARKET_CSGO_BASE_URL + '/my-inventory', query: @params)
        # MissingItemsService.new(@current_user).missing_items(response)
        # save_inventory(response, @active_steam_account) if response['success'] == true
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.market_csgo_api_key.blank?
        begin

          response = self.class.get(MARKET_CSGO_BASE_URL + '/my-inventory', query: site_params(steam_account))
          # MissingItemsService.new(@current_user).missing_items(response)
          # save_inventory(response, steam_account) if response['success'] == true
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
      end
    end
  end

  def sold_item_params(steam_account)
    { 
      key: "#{steam_account&.market_csgo_api_key}",
      date: Date.today.strftime("%d-%m-%Y")
    }
  end

  def save_sold_items(data, steam_account)
    data.each do |item|
      if item['event'] == 'sell' && item['stage'] == '2'
        sold_item = SoldItem.find_by(item_id: id)
        inventory_item = SellableInventory.find_by(item_id: item['item_id'])
        bought_price = inventory_item.present? ? inventory_item.market_price.to_f : 0
        SoldItem.create(item_id: item['item_id'], item_name: item['market_hash_name'], bought_price: (bought_price / 100.to_f), sold_price: (item['received'] / 1000.to_f), date: Date.today.strftime("%d-%m-%Y"), steam_account: steam_account) unless sold_item.present?
      end
    end
  end

  def self.fetch_sold_item_market_csgo(steam_account)
    begin
      response = self.class.get(MARKET_CSGO_BASE_URL + '/history', query: sold_item_params(steam_account))
      if response['success'] == true
        save_sold_items(response['data'], steam_account) if response['data'].present?
      end
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end
  end
    
  def active_trades
    response = []
    if @active_steam_account.present?
      return [] if market_csgo_api_key_not_found?
      begin
        res = self.class.get(MARKET_CSGO_BASE_URL + '/trades', query: @active_trade_query)
      rescue => e
        response = [{ success: "false" }]
      end
      if res['success'] == false
        report_api_error(res, [self&.class&.name, __method__.to_s])
        response = [{ success: "false" }]
      else
        response = res['trades'] if res['trades'].present?
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.market_csgo_api_key.blank?
        begin
          res = self.class.get(MARKET_CSGO_BASE_URL + '/trades', query: site_active_trade_params(steam_account))
          if res['success'] == true
            if res['trades'].present?
              res['trades'].each do |auctions|
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

  def fetch_items_listed_for_sale_market_csgo
    if @active_steam_account.present?
      return [] if market_csgo_api_key_not_found?
        res = self.class.get(MARKET_CSGO_BASE_URL + '/items', query: @params)
      if res["success"] == false
        report_api_error(res, [self&.class&.name, __method__.to_s])
        response = [{ success: "false" }]
      else
        response = res["items"].present? ? res["items"] : []
      end
    else
      response = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.market_csgo_api_key.blank?
        add_proxy(steam_account) if steam_account.proxy.present?
        res = self.class.get(MARKET_CSGO_BASE_URL + '/items', query: site_params(steam_account))
        if res["success"] == false
          response = [{ success: "false" }]
          break
        end
        response += res["items"].present? ? res["items"] : []
      end
    end
    response
  end

  def self.fetch_inventory(steam_account)
    return if steam_account.market_csgo_api_key.blank?

    response = []
    begin
      response = HTTParty.get(MARKET_CSGO_BASE_URL + '/my-inventory', query: { key: "#{steam_account&.market_csgo_api_key}" })
      # MissingItemsService.new(@current_user).missing_items(response)
      # save_inventory(response, @active_steam_account) if response['success'] == true
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end
    response
  end

  def market_csgo_api_key_not_found?
    @active_steam_account&.market_csgo_api_key.blank?
  end

  def add_proxy(steam_account)
    proxy = steam_account.proxy
    self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
  end
end