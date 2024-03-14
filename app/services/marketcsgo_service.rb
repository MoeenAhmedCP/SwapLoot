class MarketcsgoService < ApplicationService
  include HTTParty  

  def initialize(current_user)
    @active_steam_account = current_user.active_steam_account
    @current_user = current_user
    @params = {
      key: "#{@active_steam_account&.market_csgo_api_key}"
    }
    reset_proxy
    add_proxy(@active_steam_account) if @active_steam_account&.proxy.present?
  end

  def site_params(steam_account)
    { key: "#{steam_account&.market_csgo_api_key}" }
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

  def fetch_items_listed_for_sale_market_csgo
    if @active_steam_account.present?
      return [] if market_csgo_api_key_not_found?
        response = self.class.get(MARKET_CSGO_BASE_URL + '/items', query: @params)
      if response["success"] == false
        report_api_error(res, [self&.class&.name, __method__.to_s])
        response = [{ success: "false" }]
      else
        response = response["items"].present? ? response["items"] : []
      end
    else
      response = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.market_csgo_api_key.blank?
        add_proxy(steam_account) if steam_account.proxy.present?
          response = self.class.get(MARKET_CSGO_BASE_URL + '/items', query: site_params(steam_account))
        if response["success"] == false
          response = [{ success: "false" }]
          break
        end
        response += response["items"].present? ? response["items"] : []
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