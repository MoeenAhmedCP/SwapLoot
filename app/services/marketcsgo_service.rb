class MarketcsgoService
  include HTTParty  

  def initialize(current_user)
    @active_steam_account = current_user.active_steam_account
    @params = {
      key: "#{@active_steam_account&.market_csgo_api_key}"
    }
  end

  def fetch_balance
    return if market_csgo_api_key_not_found?

    res = self.class.get(MARKET_CSGO_BASE_URL + '/get-money', query: @params)
    res['money'] if res
  end

  def market_csgo_api_key_not_found?
    @active_steam_account&.market_csgo_api_key.blank?
  end
end
