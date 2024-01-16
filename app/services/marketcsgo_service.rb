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

  def market_csgo_api_key_not_found?
    @active_steam_account&.market_csgo_api_key.blank?
  end

  def add_proxy(steam_account)
    proxy = steam_account.proxy
    self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
  end
end
