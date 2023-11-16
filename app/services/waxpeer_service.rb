class WaxpeerService
  include HTTParty

  BASE_URL = 'https://api.waxpeer.com/v1'

  def initialize(current_user)
    @current_user = current_user
    @active_steam_account = SteamAccount.find_by(active: true, user_id: @current_user.id)
    @params = {
      api: @active_steam_account&.waxpeer_api_key
    }
  end

  def fetch_active_trade
    res = self.class.post(BASE_URL + '/my-history', query: @params)
    res['data'].present? ? res['data']['trades'] : []
  end

  def fetch_item_listed_for_sale
    params = {
      api: api_key
    }
    res = self.class.get(BASE_URL + '/list-items-steam', query: params)
    res['items'].present? ? res['items'] : []
  end

  def fetch_balance
    res = self.class.get(BASE_URL + '/user', query: @params)
    res['user'].present? ? res['user']['wallet'].to_f / 1000 : 0
  end
end
