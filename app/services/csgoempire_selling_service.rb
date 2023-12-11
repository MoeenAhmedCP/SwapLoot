class CsgoempireSellingService < ApplicationService
  include HTTParty
  require 'json'

  def initialize(steam_account)
    @steam_account = steam_account
  end
  
  def fetch_inventory
    headers = { 'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}" }
    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers)

    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s]) 
    else
      response = response["data"].select { |item| item["market_value"] != -1 && item["tradable"] == true }
      online_trades_response = HTTParty.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers)

      if online_trades_response['success'] == false
        report_api_error(online_trades_response, [self&.class&.name, __method__.to_s])
      else
        online_trades = JSON.parse(online_trades_response.read_body)
        api_item_ids = online_trades["data"]["deposits"].map { |deposit| deposit["item_id"] }
        filtered_response = response.reject { |item| api_item_ids.include?(item["id"]) }
      end
    end
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
      if item["average"] > (item["coin_value_bought"] + (item["coin_value_bought"] * @steam_account.selling_filter.min_profit_percentage / 100 ).round(2)) * 100
        { "id" => item["id"], "coin_value" => item["average"] }
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


    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s])
    else
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
          if item_ready_to_price_cutting?(item[:updated_at], @steam_account.selling_filter.undercutting_interval)
          items_for_resale << item
        end
      end
      items_for_resale.any? ? cutting_price_and_list_again(items_for_resale) : price_cutting_down_for_listed_items
    # else
    #   price_cutting_down_for_listed_items
    end
  end

  def cancel_item_deposit(item)
    headers = {
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
    }
    response = HTTParty.post(CSGO_EMPIRE_BASE_URL + "/trading/deposit/#{item[:deposit_id]}/cancel", headers: headers)

    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s])
    end

    puts response.code == SUCCESS_CODE ? "#{item[:market_name]}'s deposit has been cancelled." : "Something went wrong with #{item[:item_id]} - #{item[:market_name]} Unable to Cancel Deposit."
  end
  
  def cutting_price_and_list_again(items)
    filtered_items_for_deposit = []
    items.map do |item|
      suggested_items = waxpeer_suggested_prices
      result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
      item_price = Inventory.find_by(item_id: item[:item_id]).market_price
      lowest_price = (result_item['lowest_price'].to_f / 1000 / 0.614).round(2)
      minimum_desired_price = (item_price + (item_price * @steam_account.selling_filter.min_profit_percentage / 100 )).round(2)
      if result_item && lowest_price > minimum_desired_price
        filtered_items_for_deposit << item.merge(:lowest_price=> result_item["lowest_price"])
      end
    end

    filtered_items_for_deposit.each do |item_to_deposit|
      cancel_item_deposit(item_to_deposit)
    end
    items_to_deposit = filtered_items_for_deposit.map { |filtered_item| { "id"=> filtered_item[:item_id], "coin_value"=> calculate_pricing(filtered_item) } }
    deposit_items_for_resale(items_to_deposit)
  end

  def search_items_by_names(item)
    url = "https://api.waxpeer.com/v1/search-items-by-name?api=#{@steam_account.waxpeer_api_key}&game=csgo&names=#{item[:market_name]}&minified=0"
    response = HTTParty.get(url)

    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s])
    else
      response
    end
  end

  def calculate_pricing(item)
    (((item[:lowest_price]/1000.to_f / 0.614 ).round(2) - 0.01) * 100).to_i
    # deposit_value = (item[:total_value]) - (( item[:total_value] * percentage )/100)
  end

  def item_ready_to_price_cutting?(updated_at, no_of_minutes)
    updated_time = updated_at.to_datetime
    estimated_time = Time.current + no_of_minutes.minutes
    updated_time <= estimated_time
  end

  def deposit_items_for_sale(items)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
    }
    items.each do |item|
      hash = {"items"=> [item]}
      response = HTTParty.post(CSGO_EMPIRE_BASE_URL + '/trading/deposit', headers: headers, body: JSON.generate(hash))
      if response.code == SUCCESS_CODE
        result = JSON.parse(response.body)
      else
        report_api_error(response, [self&.class&.name, __method__.to_s])
        result = API_FAILED
      end
    end
    sell_csgoempire
  end

  def deposit_items_for_resale(items)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
    }
    hash = {"items"=> items}
    response = HTTParty.post(CSGO_EMPIRE_BASE_URL + '/trading/deposit', headers: headers, body: hash.to_json)
    if response.code == SUCCESS_CODE
      result = JSON.parse(response.body)
    else
      result = API_FAILED
    end
    price_cutting_down_for_listed_items
  end


  def find_matching_items(response_items, inventory)
    matching_items = []
    inventory_hash = inventory.each_with_object({}) do |item, hash|
      hash[item['market_name']] = item
    end
    response_items.each do |item|
      market_name = item.item_name
      if inventory_hash.key?(market_name)
        waxpeer_price = item["waxpeer"]["price"]
        buff_price = item["buff"]["price"]
        greater_price = [waxpeer_price, buff_price].max
        matching_item = {
          'id' => inventory_hash[market_name]['id'],
          'name' => market_name,
          'average' => ((greater_price/100.to_f / 0.614 - 0.01) * 100).round, #final
          'coin_value_bought' => inventory_hash[market_name]['market_value'].to_f / 100,
          'coin_to_dollar' => inventory_hash[market_name]['market_value'].to_f / 100 * 0.614
        }
        matching_items << matching_item
      end
    end
    return matching_items
  end

  def waxpeer_suggested_prices
     response = HTTParty.get(WAXPEER_BASE_URL + '/suggested-price?game=csgo')
     if response.code == SUCCESS_CODE
       result = JSON.parse(response.body)
     else
        report_api_error(response, [self&.class&.name, __method__.to_s])
        result = API_FAILED
     end
     result
  end

  def fetch_items
    response = PriceEmpire.all
  end
end

