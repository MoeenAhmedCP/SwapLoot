class CsgoempireService
  include HTTParty

  BASE_URL = 'https://csgoempire.com/api/v2'

  def fetch_my_inventory
    headers = { 'Authorization' => "Bearer #{ENV['CSGOEMPIRE_TOKEN']}" }
    response = self.class.get(BASE_URL + '/trading/user/inventory', headers: headers)

    save_inventory(response)
  end

  def fetch_balance
    headers = { 'Authorization' => "Bearer #{ENV['CSGOEMPIRE_TOKEN']}" }
    response = self.class.get(BASE_URL + '/metadata/socket', headers: headers)
    response['user']['balance']
  end

  def save_inventory(res)
    res['data'].each do |item|
      Inventory.create(item_id: item['asset_id'], market_name: item['market_name'], market_price: item['market_value'], tradable: item['tradable'])
    end
  end
end
