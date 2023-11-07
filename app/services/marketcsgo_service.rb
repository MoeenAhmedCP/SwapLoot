class MarketcsgoService
  include HTTParty

  BASE_URL = 'https://market.csgo.com/api/v2'

  def fetch_my_inventory
    params = {
      key: "#{ENV['MARKETCSGO_KEY']}"
    }
    response = self.class.get(BASE_URL + '/my-inventory', query: params)

    save_inventory(response)
  end

  def save_inventory(res)
    res['items'].each do |item|
      Inventory.create(item_id: item['id'], market_name: item['market_hash_name'], market_price: item['market_price'], tradable: item['tradable'])
    end
  end
end
