class CsgoempireSellingService 
  include HTTParty

  BASE_URL = 'https://csgoempire.com/api/v2'

  def get_inventory
    headers = { 'Authorization' => "Bearer #{ENV['CSGOEMPIRE_TOKEN']}" }
    response = self.class.get(BASE_URL + '/trading/user/inventory', headers: headers)
  end

  def sell_csgoempire(margin, margin_flag)
    res = get_items
    inv = JSON.parse(get_inventory.read_body)["data"]
    matching_items = find_matching_items(res, inv)
    #sell API
  end

  def find_matching_items(res, inv)
    matching_items = []
    # Create a hash for quick look-up of items in the inventory
    inv_hash = inv.each_with_object({}) do |item, hash|
      hash[item['market_name']] = item
    end
    res["items"].each do |item|
      market_name = item['name']
      # If the item is present in the inventory, add it to the matching_items array
      if inv_hash.key?(market_name)
        matching_item = {
          'name' => market_name,
          'average' => item['average'].to_f / 1000,
          'coin_value_bought' => inv_hash[market_name]['market_value'].to_f / 100,
          'coin_to_dollar' => inv_hash[market_name]['market_value'].to_f / 100 * 0.613
        }
        matching_items << matching_item
      end
    end
    return matching_items
  end

  def get_items
     response = HTTParty.get("https://api.waxpeer.com/v1/suggested-price?game=csgo")
     if response.code == 200
       result = JSON.parse(response.body)
     else
       result = "API request failed"
     end
     result
  end

end