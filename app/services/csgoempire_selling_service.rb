class CsgoempireSellingService 
  include HTTParty
  require 'json'

  def initialize(steam_account)
    @steam_account = steam_account
  end
  
  def fetch_inventory
    headers = { 'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}" }
    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers)
    response = response["data"].select { |item| item["market_value"] != -1 }
    online_trades_response = HTTParty.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers)
    online_trades = JSON.parse(online_trades_response.read_body)
    api_item_ids = online_trades["data"]["deposits"].map { |deposit| deposit["item_id"] }
    filtered_response = response.reject { |item| api_item_ids.include?(item["id"]) }
  end

  def find_matching_data
    response_items = fetch_items
    inventory = (fetch_inventory.map {|item| item if item["tradable"] == true }.compact)
    inventory ? matching_items = find_matching_items(response_items, inventory) : []
  end
  
  def sell_csgoempire
    matching_items =  find_matching_data 
    unless matching_items
      sell_csgoempire
    end
    items_to_deposit = matching_items.map do |item|
      if item["average"] > item["coin_to_dollar"]
        { "id" => item["id"], "coin_value" => ((item["average"] / 0.614) * 100).round }
      else
        next
      end
    end
    deposit_items_for_sale(items_to_deposit)
  end

  def price_cutting_down_for_listed_items
    headers = {
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
    }
    response = HTTParty.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers)
    api_response = JSON.parse(response.read_body)
    # Sample API response is at the end of the file, You can use it for testing (here).
    items_listed_for_sale = []
    items_listed_for_sale = api_response["data"]["deposits"].map do |deposit|
      {
        deposit_id: deposit["id"],
        item_id: deposit["item_id"],
        market_name: deposit["item"]["market_name"],
        total_value: deposit["total_value"],
        market_value: deposit["item"]["market_value"],
        updated_at: deposit["item"]["updated_at"],
        auction_number_of_bids: deposit["metadata"]["auction_number_of_bids"],
        suggested_price: deposit["suggested_price"]
      }
    end
    items_for_resale = []
    items_listed_for_sale.each do |item|
        if !item_ready_to_price_cutting?(item[:updated_at], @steam_account.selling_filter.undercutting_interval) && item[:auction_number_of_bids] == 0 # variable
        items_for_resale << item
      end
    end
    cutting_price_and_list_again(items_for_resale, @steam_account.selling_filter.undercutting_price_percentage) #variable
  end

  def cancel_item_deposit(item)
    headers = {
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
    }
    response = HTTParty.post(CSGO_EMPIRE_BASE_URL + "/trading/deposit/#{item[:deposit_id]}/cancel", headers: headers)
    puts response.code == SUCCESS_CODE ? "#{item[:market_name]}'s deposit has been cancelled." : "Something went wrong with #{item[:item_id]} - #{item[:market_name]} Unable to Cancel Deposit."
  end
  
  def cutting_price_and_list_again(items, percentage)
    suggested_prices = fetch_items
    cheapest_price = []
    filtered_items_for_deposit = []
    items.map do |item|
      deposit_value = calculate_pricing(item, percentage)
      suggested_prices["items"].each do |suggested_item|
        cheapest_price << suggested_item["lowest_price"] if suggested_item["name"] ==  item[:market_name]
      end
      if deposit_value >= ((cheapest_price.first.to_f / 1000) * 0.614 * 100).round && deposit_value >= (item[:market_value] + (item[:market_value]/100) * @steam_account.selling_filter.min_profit_percentage) #variable
        cheapest_owned = false
        items_by_names_search = search_items_by_names(item)
        items_by_names_search["items"].each do |search_item|
          if search_item["item_id"] == item[:item_id] && search_item["price"] == cheapest_price.first
            cheapest_owned = true
          end
        end
        filtered_items_for_deposit << item unless cheapest_owned
      else
        next
      end
    end
    filtered_items_for_deposit.each do |item_to_deposit|
      cancel_item_deposit(item_to_deposit)
    end
    items_to_deposit = filtered_items_for_deposit.map { |item| { "id"=> item[:item_id], "coin_value"=> calculate_pricing(item, percentage) } }
    deposit_items_for_sale(items_to_deposit[0])
  end

  def search_items_by_names(item)
    url = "https://api.waxpeer.com/v1/search-items-by-name?api=#{@steam_account.waxpeer_api_key}&game=csgo&names=#{item[:market_name]}&minified=0"
    response = HTTParty.get(url)
  end

  def calculate_pricing(item, percentage)
    deposit_value = (item[:total_value]) - (( item[:total_value] * percentage )/100)
  end

  def item_ready_to_price_cutting?(updated_at, no_of_hours)
    updated_time = updated_at.to_datetime
    twelve_hours_from_now = Time.current + no_of_hours.seconds
    updated_time >= twelve_hours_from_now
  end

  def deposit_items_for_sale(items)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
    }
    array = []
    array << items
    hash = {"items"=> array} 
    response = HTTParty.post(CSGO_EMPIRE_BASE_URL + '/trading/deposit', headers: headers, body: hash.to_json)
    if response.code == SUCCESS_CODE
      result = JSON.parse(response.body)
    else
      result = API_FAILED
    end
    result
  end


  def find_matching_items(response_items, inventory)
    matching_items = []
    inventory_hash = inventory.each_with_object({}) do |item, hash|
      hash[item['market_name']] = item
    end
    response_items["items"].each do |item|
      market_name = item['name']
      if inventory_hash.key?(market_name)
        matching_item = {
          'id' => inventory_hash[market_name]['id'],
          'name' => market_name,
          'average' => item['average'].to_f / 1000,
          'coin_value_bought' => inventory_hash[market_name]['market_value'].to_f / 100,
          'coin_to_dollar' => inventory_hash[market_name]['market_value'].to_f / 100 * 0.614
        }
        matching_items << matching_item
      end
    end
    return matching_items
  end

  def fetch_items
     response = HTTParty.get(WAXPEER_BASE_URL + '/suggested-price?game=csgo')
     if response.code == SUCCESS_CODE
       result = JSON.parse(response.body)
     else
       result = API_FAILED
     end
     result
  end
end