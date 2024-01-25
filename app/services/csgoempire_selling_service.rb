class CsgoempireSellingService < ApplicationService
  include HTTParty
  require 'json'

  #initialize steam account fro service
  def initialize(steam_account)
    @steam_account = steam_account
    add_proxy
  end

  def headers
    {
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
      'Content-Type' => 'application/json'
    }
  end

  def add_proxy
    reset_proxy
    proxy = @steam_account.proxy
    self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
  end

  def add_proxy
    reset_proxy
    proxy = @steam_account.proxy
    self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
  end

  def fetch_inventory
    response = fetch_database_inventory
    online_trades_response = fetch_active_trades
    if online_trades_response['success'] == false
      report_api_error(online_trades_response, [self&.class&.name, __method__.to_s])
    else
      online_trades = JSON.parse(online_trades_response.read_body)
      api_item_ids = online_trades["data"]["deposits"].map { |deposit| deposit["item_id"] }
      filtered_response = response.reject { |item| api_item_ids.include?(item["id"]) }
    end
    filtered_response
  end

  # function to fetch matching items data from inventory and price empire api
  def find_matching_data
    price_empire_response_items = fetch_items_from_pirce_empire
    waxpeer_response_items = waxpeer_suggested_prices if price_empire_response_items.empty?
    inventory = fetch_inventory
    if inventory.present?
      if price_empire_response_items.present?
        matching_items = find_matching_items(price_empire_response_items, inventory)
      elsif waxpeer_response_items.present?
        matching_items = find_waxpeer_matching_items(waxpeer_response_items, inventory)
      end
    else
      matching_items = []
    end
    matching_items
  end

  # function to initiate selling service from toggle of web app
  def sell_csgoempire
    matching_items = find_matching_data
    unless matching_items
      sell_csgoempire
    end
    if fetch_items_from_pirce_empire.present?
      items_to_deposit = matching_items.map do |item|
        if item["average"] > (item["coin_value_bought"] + ((item["coin_value_bought"] * @steam_account.selling_filter.min_profit_percentage) / 100 ).round(2))
          { "id" => item["id"], "coin_value" => item["average"] }
        else
          next
        end
      end
    else
      items_to_deposit = matching_items
    end
    deposit_items_for_sale(items_to_deposit)

    # Items list from waxpeer that were not found on PriceEmpire
    @inventory = fetch_database_inventory
    remaining_items = @inventory&.reject { |inventory_item| matching_items.any? { |matching_item| matching_item["id"] == inventory_item.item_id && matching_item["name"] == inventory_item.market_name } }
    if remaining_items.any?
      filtered_items_for_deposit = []
      remaining_items.each do |item|
        suggested_items = waxpeer_suggested_prices
        result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
        item_price = SellableInventory.find_by(item_id: item[:item_id]).market_price
        lowest_price = (result_item['lowest_price'].to_f / 1000 / 0.614).round(2)
        minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 )).round(2)
        if result_item && lowest_price > minimum_desired_price
          filtered_items_for_deposit << JSON.parse(item.to_json).merge(:lowest_price => result_item["lowest_price"])
        end
      end
      remaining_items_to_deposit = filtered_items_for_deposit.map { |filtered_item| { "id"=> filtered_item["item_id"], "coin_value"=> calculate_pricing(filtered_item) } }
      deposit_items_for_sale(remaining_items_to_deposit) if remaining_items_to_deposit.any?
    end
  end

  # fucntion to get active trades and prepare items which are ready for price cutting
  def price_cutting_down_for_listed_items
    response = fetch_active_trades
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
          updated_at: deposit["created_at"],
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
      if items_for_resale.any?
        cutting_price_and_list_again(items_for_resale)
      else
        price_cutting_job_id = PriceCuttingJob.perform_in(@steam_account.selling_filter.undercutting_interval.minutes, @steam_account.id)
        @steam_account.trade_service.update(price_cutting_job_id: price_cutting_job_id)
      end
    end
  end

  # function to cancel deposit of the items listed for sale
  def cancel_item_deposit(item)
    response = HTTParty.post(CSGO_EMPIRE_BASE_URL + "/trading/deposit/#{item[:deposit_id]}/cancel", headers: headers)
    if response['success'] == true
      sellable_item = SellableInventory.find_by(item_id: item[:item_id])
      sellable_item.update(listed_for_sale: false) if sellable_item.present?
    else
      report_api_error(response, [self&.class&.name, __method__.to_s])
    end
    puts response.code == SUCCESS_CODE ? "#{item[:market_name]}'s deposit has been cancelled." : "Something went wrong with #{item[:item_id]} - #{item[:market_name]} Unable to Cancel Deposit."
  end
  
  # Function for Cutting Prices of Items and List them again for sale
  def cutting_price_and_list_again(items)
    filtered_items_for_deposit = []
    items.map do |item|
      suggested_items = waxpeer_suggested_prices
      result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
      item_price = SellableInventory.find_by(item_id: item[:item_id]).market_price
      lowest_price = (result_item['lowest_price'].to_f / 1000 / 0.614).round(2)
      minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 )).round(2)
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

  #Function for search items by (:market_name) from Waxpeer API 
  def search_items_by_names(item)
    url = "https://api.waxpeer.com/v1/search-items-by-name?api=#{@steam_account.waxpeer_api_key}&game=csgo&names=#{item[:market_name]}&minified=0"
    response = HTTParty.get(url)

    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s])
    else
      response
    end
  end

  # Function for the conversion of dollars to coins for listing items
  def calculate_pricing(item)
    (((item[:lowest_price]/1000.to_f / 0.614 ).round(2) - 0.01) * 100).to_i
  end

  # function to check if the items are ready to price cutting, (e.g. Intervel is completed)
  def item_ready_to_price_cutting?(updated_at, no_of_minutes)
    estimated_time = updated_at.to_datetime + no_of_minutes.minutes
    estimated_time <= Time.current
  end

  # function to list items for sale at the first item on price empire suggested prices (Waxpeer/Buff)
  def deposit_items_for_sale(items)
    items.each do |item|
      hash = {"items" => [item]}
      response = HTTParty.post(CSGO_EMPIRE_BASE_URL + '/trading/deposit', headers: headers, body: JSON.generate(hash))
      if response.code == SUCCESS_CODE
        SellableInventory.find_by(item_id: item["id"]).update(listed_for_sale: true)
        result = JSON.parse(response.body)
      else
        report_api_error(response, [self&.class&.name, __method__.to_s])
        result = API_FAILED
      end
    end
    # sell_csgoempire
  end

  # Function to List Items again for resale after price cutting algorithm
  def deposit_items_for_resale(items)
    items.each do |item|
      hash = {"items": [item]}
      response = HTTParty.post(CSGO_EMPIRE_BASE_URL + '/trading/deposit', headers: headers, body: JSON.generate(hash))
      if response.code == SUCCESS_CODE
        SellableInventory.find_by(item_id: item["id"]).update(listed_for_sale: true)
        result = JSON.parse(response.body)
      else
        report_api_error(response, [self&.class&.name, __method__.to_s])
        result = API_FAILED
      end
    end
    price_cutting_down_for_listed_items
  end

 # function to fetch matching items between Price Empire API data and Inventory Data
  def find_matching_items(response_items, inventory)
    matching_items = []
    inventory.each do |inventory_item|
      item_found_from_price_empire = response_items.find_by(item_name: inventory_item.market_name)
      if item_found_from_price_empire
        buff_price = item_found_from_price_empire["buff"]["price"]
        matching_item = {
          'id' => inventory_item.item_id,
          'name' => inventory_item.market_name,
          'average' => ((buff_price/100.to_f / 0.614 - 0.01) * 100).round, #final coin x 100
          'coin_to_dollar' => (inventory_item.market_price.to_f) * 100, # /0.614 dollar value bought
          'coin_value_bought' => (inventory_item.market_price.to_f / 0.614) * 100 #dollar to coin
        }
        matching_items << matching_item
      else
        next
      end
    end
    return matching_items
  end

  def find_waxpeer_matching_items(waxpeer_response_items, inventory)
    matching_items = []
    inventory.map do |item|
      suggested_items = waxpeer_suggested_prices
      result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
      item_price = SellableInventory.find_by(item_id: item[:item_id]).market_price
      lowest_price = (result_item['lowest_price'].to_f / 1000 / 0.614).round(2)
      minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 )).round(2)
      if result_item && lowest_price > minimum_desired_price
        matching_items << item.attributes.merge(lowest_price: result_item["lowest_price"])
      end
    end
    matching_items.map do |filtered_item|
      { "id"=> filtered_item["item_id"], "coin_value"=> calculate_pricing(filtered_item) } 
    end
  end

  # Fetch Suggested price of items from Waxpeer
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

  # Function to fetch Items and Its Prices from different platforms from Price Empire API
  def fetch_items_from_pirce_empire
    response = PriceEmpire.all
  end

  # Remove Items listed for sale when the selling is turned off
  def remove_listed_items_for_sale
    active_trades = fetch_active_trades
    begin
      if active_trades["data"]["deposits"]&.present? && active_trades["data"].present?
        items_listed_for_sale = []
        items_listed_for_sale = active_trades["data"]["deposits"].map do |deposit|
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
          cancel_item_deposit(item)
        end
        return true
      end
    rescue
      return false
    end
  end

# Function to fecth active trades
  def fetch_active_trades
    headers = {
      'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}",
    }
    HTTParty.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers)
  end

  def fetch_database_inventory
    SellableInventory.inventory(@steam_account).where(listed_for_sale: false)
  end
end