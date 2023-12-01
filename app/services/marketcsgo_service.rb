class MarketcsgoService < ApplicationService
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

    if res['success'] == false
      report_api_error(res&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      res['money']
    end
  end

  def market_csgo_api_key_not_found?
    @active_steam_account&.market_csgo_api_key.blank?
  end
end
