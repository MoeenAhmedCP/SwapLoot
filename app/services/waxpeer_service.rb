class WaxpeerService
  include HTTParty

  BASE_URL = 'https://api.waxpeer.com/v1'

  def fetch_active_trade
    params = {
      api: api_key
    }
    res = self.class.post(BASE_URL + '/my-history', query: params)
    res['data'].present? ? res['data']['trades'] : []
  end

  def fetch_balance
    params = {
      api: api_key
    }
    res = self.class.get(BASE_URL + '/user', query: params)
    res['user'].present? ? res['user']['wallet'].to_f / 1000 : 0
  end

  def api_key
    @active_steam_account = SteamAccount.find_by(active: true)
    @active_steam_account&.waxpeer_api_key
  end
end
