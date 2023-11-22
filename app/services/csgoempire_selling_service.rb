class CsgoempireSellingService 
  include HTTParty
  require 'json'

  def fetch_inventory
    headers = { 'Authorization' => "Bearer #{SteamAccount.last.csgoempire_api_key}" }
    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers)
  end

  def find_matching_items
    response_items = fetch_items
    inventory = JSON.parse(fetch_inventory.read_body)["data"]
    matching_items = find_matching_items(response_items, inventory)
  end
  
  def sell_csgoempire
    matching_items = find_matching_items
    items_to_deposit = matching_items.map { |item| { :id => item["id"], :coin_value => item["average"] } }
    deposit_items_for_sale(items_to_deposit)
  end

  def price_cutting_down_for_listed_items
    headers = {
      'Authorization' => "Bearer #{SteamAccount.last.csgoempire_api_key}",
      "Cookie" => "__cf_bm=UC0VagvyDsTU3NW.KuK6WbrcI5ni5ci043TTwYyk_OQ-1700497991-0-ASt0QjgTlGMcECzgNGFufCXeTENyMhxT+GX8Ghjk3odvvJMUrcbAHMbDgfDw9ylq/rOBPZBDj6gsKNFnw3XTHic="
    }
    response = HTTParty.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers)
    items_listed_for_sale = []
    api_response = JSON.parse(response.read_body)
    # Sample API response is at the end of the file, You can use it for testing (here).
    items_listed_for_sale = api_response["data"]["deposits"].map do |deposit|
      {
        deposit_id: deposit["id"],
        item_id: deposit["item_id"],
        market_name: deposit["item"]["market_name"],
        total_value: deposit["total_value"],
        market_value: deposit["item"]["market_value"],
        updated_at: deposit["created_at"],
        auction_number_of_bids: deposit["metadata"]["auction_number_of_bids"],
        suggested_price: deposit["suggested_price"]
      }
    end
    
    items_listed_for_sale.each do |item|
      if item_ready_to_price_cutting?(item[:updated_at], 12) && item[:auction_number_of_bids] == 0
        cancel_item_deposit(item)
      end
    end
    cutting_price_and_list_again(items_for_resale, 10)
  end

  def cancel_item_deposit(item)
    items_for_resale = []
    headers = {
      'Authorization' => "Bearer #{SteamAccount.last.csgoempire_api_key}",
      "Cookie" => "__cf_bm=yAIsU9h5U_O_l3yUPZIgzGItYspo533di02Gn.dHsY4-1700564804-0-ARdWAD5NLqEeMUL2rCEelGWstnMtReqLU1I+oaaAZvH9S7mLTToJnPncNRU7tKcHHo3f5+RtnxbL0TzRLEloDBc="
    }
    response = HTTParty.post(CSGO_EMPIRE_BASE_URL + "/trading/deposit/#{item[:deposit_id]}/cancel", headers: headers)
    puts response.code == SUCCESS_CODE ? "#{item[:market_name]}'s deposit has been cancelled." : "Something went wrong with #{item[:item_id]} - #{item[:market_name]} Unable to Cancel Deposit."
    items_for_resale << item
  end
  
  def cutting_price_and_list_again(items, percentage)
    items_to_deposit = items.map { |item| { :id => item["id"], :coin_value => ( item["average"]/100 ) * ( percentage ).to_f } }
    deposit_items_for_sale(items_to_deposit)
  end

  def item_ready_to_price_cutting?(updated_at, no_of_hours)
    updated_time = Time.parse(updated_at)
    twelve_hours_from_now = Time.now + no_of_hours.hours
    updated_time >= twelve_hours_from_now
  end

  def deposit_items_for_sale(items)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{SteamAccount.last.csgoempire_api_key}",
      'Cookie' => '__cf_bm=XdZ7YnR8xpnNOaggQ3Ui4N8aSMrcul_hvZzAPKFDseQ-1700236581-0-AWeGBjA6LlO2w87YE5IBwTNwC1WYhKYpWwo+j+CIA4IWYZ0L1bCFLg0/ttVIUvE2DpkIixc11qhcXa8mNQvKnI4='
    }
    body = {items: items}
    response = HTTParty.post(CSGO_EMPIRE_BASE_URL + '/trading/deposit', headers: headers, body: body.to_json)
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
#     }