class MarketcsgoService
  include HTTParty

  BASE_URL = 'https://market.csgo.com/api/v2'

  def fetch_my_inventory
    params = {
      key: ""
    }
    response = self.class.get(BASE_URL + '/my-inventory', query: params)
  end
end
