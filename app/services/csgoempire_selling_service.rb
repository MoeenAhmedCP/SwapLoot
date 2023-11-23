class CsgoempireSellingService 
  include HTTParty
  require 'json'

  # def initialize(steam_account)
  #   @steam_account = steam_account
  # end
  
  def fetch_inventory
    headers = { 'Authorization' => "Bearer #{SteamAccount.first.csgoempire_api_key}" }
    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers)
    response = response["data"].select { |item| item["market_value"] != -1 }
    online_trades_response = HTTParty.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers)
    online_trades = JSON.parse(online_trades_response.read_body)
    api_item_ids = online_trades["data"]["deposits"].map { |deposit| deposit["item_id"] }
    filtered_response = response.reject { |item| api_item_ids.include?(item["id"]) }
  end

  def find_matching_data
    response_items = fetch_items
    inventory = fetch_inventory 
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
    deposit_items_for_sale(items_to_deposit.last)
  end

  def price_cutting_down_for_listed_items
    headers = {
      'Authorization' => "Bearer #{SteamAccount.first.csgoempire_api_key}",
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
        updated_at: deposit["updated_at"],
        auction_number_of_bids: deposit["metadata"]["auction_number_of_bids"],
        suggested_price: deposit["suggested_price"]
      }
    end
    items_for_resale = []
    items_listed_for_sale.each do |item|
        if item_ready_to_price_cutting?(item[:updated_at], 12) && item[:auction_number_of_bids] == 0 # variable
        items_for_resale << item
      end
    end
    cutting_price_and_list_again(items_for_resale, 10) #variable
  end

  def cancel_item_deposit(item)
    headers = {
      'Authorization' => "Bearer #{SteamAccount.first.csgoempire_api_key}",
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
      if deposit_value >= cheapest_price.first && deposit_value >= (item[:market_value] + (item[:market_value]/100) * 2) #variable
        items_by_names_search = search_items_by_names(item)
        items_by_names_search["items"].each do |search_item|
          if search_item["item_id"] == item[:item_id]
            next
          else
            filtered_items_for_deposit << item
            cancel_item_deposit(item)
          end
        end
      else
        next
      end
    end
    items_to_deposit = filtered_items_for_deposit.map { |item| { "id"=> item[:item_id], "coin_value"=> calculate_pricing(item, percentage) } }
    deposit_items_for_sale(items_to_deposit)
  end

  def search_items_by_names(item)
    url = "https://api.waxpeer.com/v1/search-items-by-name?api=#{SteamAccount.last.waxpeer_api_key}&game=csgo&names=#{item[:market_name]}&minified=0"
    response = HTTParty.get(url)
  end

  def calculate_pricing(item, percentage)
    deposit_value = (item[:total_value]) - (( item[:total_value] * percentage )/100).to_f
  end

  def item_ready_to_price_cutting?(updated_at, no_of_hours)
    updated_time = Time.parse(updated_at)
    twelve_hours_from_now = Time.current + no_of_hours.seconds
    updated_time >= twelve_hours_from_now
  end

  def deposit_items_for_sale(items)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{SteamAccount.first.csgoempire_api_key}",
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

# api_response = {
#   "success" => true,
#   "data" => {
#     "deposits" => [
#       {
#         "id" => 206100868,
#         "total_value" => 64,
#         "item_id" => 4121724676,
#         "item" => {
#           "app_id" => 730,
#           "context_id" => 2,
#           "type" => "users",
#           "asset_id" => 34262627883,
#           "created_at" => "2021-08-31 11:28:23",
#           "full_position" => 2,
#           "icon_url" => "-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXH5ApeO4YmlhxYQknCRvCo04DEVlxkKgposbaqKAxfwPz3YzhG09C_k4if2aajMeqJlzgF6ZF10r2RrNyg3Qzjrkptazj7IYaVdwE4NFHRqFHtk-fxxcjr1j3fJ1k",
#           "id" => 4121724676,
#           "is_commodity" => false,
#           "market_name" => "Glock-18 | Candy Apple (Minimal Wear)",
#           "market_value" => 0.60,
#           "name_color" => "D2D2D2",
#           "position" => nil,
#           "preview_id" => "3c8f2fe3c8f6",
#           "price_is_unreliable" => false,
#           "stickers" => [],
#           "suggested_price" => 0.64,
#           "tradable" => true,
#           "tradelock" => false,
#           "updated_at" => "2023-11-20 15:43:53",
#           "wear" => 0.104
#         },
#         "status" => 3,
#         "status_message" => "Sending",
#         "tradeoffer_id" => 21865198,
#         "metadata" => {
#           "item_validation" => {
#             "numWrongItemDetections" => 0,
#             "validItemDetected" => false
#           },
#           "expires_at" => 1700540888,
#           "trade_url" => "https://steamcommunity.com/tradeoffer/new/?partner=914464333&token=yVAbpbd1",
#           "item_inspected" => true,
#           "partner" => {
#             "id" => 7812864,
#             "steam_id" => "76561198874730061",
#             "steam_name" => "",
#             "avatar" => "https://avatars.steamstatic.com/80613086b2449013946bd8608bc8e3a377b996f8.jpg",
#             "avatar_full" => "https://avatars.steamstatic.com/80613086b2449013946bd8608bc8e3a377b996f8_full.jpg",
#             "profile_url" => "https://steamcommunity.com/profiles/76561198874730061/",
#             "timecreated" => 1544198469,
#             "steam_level" => 14
#           },
#           "auction_ends_at" => 1700496647,
#           "auction_number_of_bids" => 0
#         },
#         "created_at" => "2023-11-20 16:07:47",
#         "suggested_price" => 64
#       },
#       {
#         "id" => 206900868,
#         "total_value" => 60,
#         "item_id" => 4121724675,
#         "item" => {
#           "app_id" => 730,
#           "context_id" => 2,
#           "type" => "users",
#           "asset_id" => 34262627883,
#           "created_at" => "2021-08-31 11:28:23",
#           "full_position" => 2,
#           "icon_url" => "-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXH5ApeO4YmlhxYQknCRvCo04DEVlxkKgposbaqKAxfwPz3YzhG09C_k4if2aajMeqJlzgF6ZF10r2RrNyg3Qzjrkptazj7IYaVdwE4NFHRqFHtk-fxxcjr1j3fJ1k",
#           "id" => 4121724675,
#           "is_commodity" => false,
#           "market_name" => "Glock-18 | Candy Banana (Minimal Wear)",
#           "market_value" => 0.60,
#           "name_color" => "D2D2D2",
#           "position" => nil,
#           "preview_id" => "3c8f2fe3c8f6",
#           "price_is_unreliable" => false,
#           "stickers" => [],
#           "suggested_price" => 0.60,
#           "tradable" => true,
#           "tradelock" => false,
#           "updated_at" => "2023-11-20 15:43:53",
#           "wear" => 0.104
#         },
#         "status" => 3,
#         "status_message" => "Sending",
#         "tradeoffer_id" => 21865198,
#         "metadata" => {
#           "item_validation" => {
#             "numWrongItemDetections" => 0,
#             "validItemDetected" => false
#           },
#           "expires_at" => 1700540888,
#           "trade_url" => "https://steamcommunity.com/tradeoffer/new/?partner=914464333&token=yVAbpbd1",
#           "item_inspected" => true,
#           "partner" => {
#             "id" => 7812864,
#             "steam_id" => "76561198874730061",
#             "steam_name" => "",
#             "avatar" => "https://avatars.steamstatic.com/80613086b2449013946bd8608bc8e3a377b996f8.jpg",
#             "avatar_full" => "https://avatars.steamstatic.com/80613086b2449013946bd8608bc8e3a377b996f8_full.jpg",
#             "profile_url" => "https://steamcommunity.com/profiles/76561198874730061/",
#             "timecreated" => 1544198469,
#             "steam_level" => 14
#           },
#           "auction_ends_at" => 1700496647,
#           "auction_number_of_bids" => 0
#         },
#         "created_at" => "2023-11-20 16:07:47",
#         "suggested_price" => 60
#       }
#     ],
#     "withdrawals" => []
#   }
# }