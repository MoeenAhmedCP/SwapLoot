class CsgoempireService
  include HTTParty

  BASE_URL = 'https://csgoempire.com/api/v2'
  HEADERS = { 'Authorization' => "Bearer #{ENV['CSGOEMPIRE_TOKEN']}" }

  def fetch_my_inventory
    response = self.class.get(BASE_URL + '/trading/user/inventory', headers: HEADERS)

    save_inventory(response)
  end

  def fetch_balance
    response = self.class.get(BASE_URL + '/metadata/socket', headers: HEADERS)
    response['user']['balance'].to_f / 100
  end

  def fetch_active_trade
    response = self.class.get(BASE_URL + '/trading/user/trades', headers: HEADERS)
  end

  def save_inventory(res)
    res['data'].each do |item|
      Inventory.find_or_create_by(item_id: item['asset_id'], market_name: item['market_name'], market_price: item['market_value'], tradable: item['tradable'])
    end
  end
end
