class MarketcsgoSellingService < ApplicationService
  include HTTParty
  require 'json'

  def initialize(steam_account)
    @steam_account = steam_account
    @params = { key: "#{@steam_account&.market_csgo_api_key}" }
    add_proxy
  end

  def add_proxy
    reset_proxy
    if @steam_account.proxy.present?
      proxy = @steam_account.proxy
      self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
    end
  end

  def find_matching_data
    price_empire_response_items = fetch_items_from_price_empire
    #waxpeer_response_items = waxpeer_suggested_prices if price_empire_response_items.empty?
    inventory = fetch_inventory
    if inventory.present?
      #if price_empire_response_items.present?
        matching_items = find_matching_items(price_empire_response_items, inventory)
      # elsif waxpeer_response_items.present?
      #   matching_items = find_waxpeer_matching_items(waxpeer_response_items, inventory)
      # end
    else
      matching_items = []
    end
    matching_items
  end

  # fucntion to get active trades and prepare items which are ready for price cutting
  def price_cutting_down_for_listed_items
    response = fetch_item_listed_for_sale_market_csgo
    if response.empty?
      report_api_error(response, [self&.class&.name, __method__.to_s])
    else
      items_for_resale = []
      response.each do |item|
        if item_ready_to_price_cutting?(item['live_time'] / 60, @steam_account.selling_filters.find_by(market_type: "market_csgo").undercutting_interval)
          items_for_resale << item
        end
      end
      if items_for_resale.any?
        cutting_price_and_list_again(items_for_resale)
      else
        price_cutting_job_id = MarketcsgoPriceCuttingJob.perform_in(@steam_account.selling_filters.find_by(market_type: "market_csgo").undercutting_interval.minutes, @steam_account.id)
        @steam_account.trade_services.market_csgo_trade_service.update(price_cutting_job_id: price_cutting_job_id)
      end
    end
  end

  def cutting_price_and_list_again(items)
    filtered_items_for_deposit = []
    items.each do |item|
      item_price = SellableInventory.find_by(item_id: item['assetid']).market_price.to_f
      minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 )).round(2)

      current_listed_price = item['price']
      price_empire_item = PriceEmpire.find_by(item_name: item['market_hash_name'])
      if price_empire_item.present?
        price_empire_item_buff_price = price_empire_item.buff["price"] * 10
        lowest_price = price_empire_item_buff_price ? price_empire_item_buff_price : nil
      end
      if lowest_price && lowest_price < current_listed_price
        filtered_items_for_deposit << item.merge("lowest_price" => lowest_price) if lowest_price >= minimum_desired_price
      else
        price_to_list = (current_listed_price - (current_listed_price * 0.05)).round(2)
        lowest_price = (price_to_list * 1000).round
        filtered_items_for_deposit << item.merge("lowest_price" => lowest_price) if lowest_price >= minimum_desired_price
      end
    end

    items_to_deposit = filtered_items_for_deposit.map { |filtered_item| { 'id' => filtered_item['item_id'], 'price' => filtered_item['lowest_price'], 'cur' => 'USD' } }
    deposit_items_for_resale(items_to_deposit) if items_to_deposit.present?
  end

  def deposit_items_for_resale(items)
    batch_process_sale_item(items, true)
    price_cutting_down_for_listed_items
  end

  def sell_market_csgo
    matching_items = find_matching_data
    unless matching_items
      sell_market_csgo
    end
    if fetch_items_from_price_empire.present?
      items_to_deposit = matching_items.map do |item|
        if item["price"] > (item["price_in_dollar"] + ((item["price_in_dollar"] * @steam_account.selling_filters.find_by(market_type: "market_csgo").min_profit_percentage) / 100 ).round(2))
          { "id" => item["id"], "price" => item["price"], 'cur' => 'USD' }
        else
          next
        end
      end
    else
      items_to_deposit = matching_items
    end
    items_to_deposit = items_to_deposit.compact
    deposit_items_for_sale(items_to_deposit) if items_to_deposit.any?
  end

  def remove_listed_items_for_sale
    response = HTTParty.get(MARKET_CSGO_BASE_URL + '/remove-all-from-sale', query: @params)
		if response.code == SUCCESS_CODE
			result = JSON.parse(response.body)
			puts "Removed: #{result["count"]} items from Market CSGO Listing."
		else
			report_api_error(response, [self&.class&.name, __method__.to_s])
			result = API_FAILED
		end
  end

  def matching_item_for_price_empire(response_items, inventory_item)
    item_found_from_price_empire = response_items.find_by(item_name: inventory_item['market_hash_name'])
    matching_item = nil
    if item_found_from_price_empire && item_found_from_price_empire["buff"].present?
      buff_price = item_found_from_price_empire["buff"]["price"] + (item_found_from_price_empire["buff"]["price"] * 0.1)
      matching_item = {
        'id' => inventory_item['id'],
        'price' => buff_price * 10,
        'cur' => 'USD',
        'price_in_dollar' => inventory_item['market_price'] * 100
      }
    end
    matching_item
  end

  def matching_item_for_marketcsgo(inventory_item)
    market_csgo_suggested_price = search_items_by_name_on_marketcsgo(inventory_item.market_name)
    matching_item = nil
    if market_csgo_suggested_price.present?
      list_price = market_csgo_suggested_price + (market_csgo_suggested_price * 0.1)
      matching_item = {
        'id' => inventory_item.item_id,
        'price' => list_price,
        'cur' => 'USD',
        'price_in_dollar' => inventory_item.market_price.to_f * 100
      }
    end
    matching_item
  end

  def find_matching_items(response_items, inventory)
    matching_items = []
    inventory.each do |inventory_item|
      matching_item = matching_item_for_marketcsgo(inventory_item)
      matching_items << matching_item if matching_item.present?
    end
    matching_items
  end

  def deposit_items_for_sale(items)
    batch_process_sale_item(items, false)
    # sell_csgoempire
  end

  def batch_process_sale_item(items, undercut)
    items.each do |item|
      if undercut
        batch_hash = {
          key: "#{@steam_account&.market_csgo_api_key}",
          item_id: item['id'],
          price: item['price'],
          cur: item['cur']
        }
        response = HTTParty.post(MARKET_CSGO_BASE_URL + '/set-price', query: batch_hash)
      else
        batch_hash = {
          key: "#{@steam_account&.market_csgo_api_key}",
          id: item['id'],
          price: item['price'],
          cur: item['cur']
        }
        response = HTTParty.post(MARKET_CSGO_BASE_URL + '/add-to-sale', query: batch_hash)
      end

      if response.code == SUCCESS_CODE
        # batch.each do |item|
        #   SellableInventory.find_by(item_id: item["id"]).update(listed_for_sale: true)
        # end
        result = JSON.parse(response.body)
      else
        report_api_error(response, [self&.class&.name, __method__.to_s])
        result = API_FAILED
      end
    end
  end

  def search_items_by_name_on_marketcsgo(item_name)
    suggested_price = nil
    url = 'https://market.csgo.com/api/v2/search-item-by-hash-name-specific'
    q_params = {
      key: @steam_account&.market_csgo_api_key,
      hash_name: item_name
    }
    response = HTTParty.get(url, query: q_params)
    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s])
    else
      if response['data'].present?
        suggested_price = response['data'].first['price']
      end
    end
    suggested_price
  end

  def item_ready_to_price_cutting?(updated_at, no_of_minutes)
    updated_at >= no_of_minutes
  end

  def fetch_items_from_price_empire
    response = PriceEmpire.all
  end

  def fetch_inventory
    response = fetch_database_inventory
    # online_trades_response = fetch_active_trades
    # if online_trades_response['success'] == false
    #   report_api_error(online_trades_response, [self&.class&.name, __method__.to_s])
    # else
    #   online_trades = JSON.parse(online_trades_response.read_body)
    #   api_item_ids = online_trades["data"]["deposits"].map { |deposit| deposit["item_id"] }
    #   filtered_response = response.reject { |item| api_item_ids.include?(item["id"]) }
    # end
    # filtered_response
  end

  private

  def fetch_item_listed_for_sale_market_csgo
    url = 'https://market.csgo.com/api/v2/items'
    q_params = {
      key: @steam_account&.market_csgo_api_key
    }
    item_listed_for_sale = []
    response = HTTParty.get(url, query: q_params)
    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s])
    else
      if response['items'].present?
        response['items'].each do |item|
          item_listed_for_sale << item if item['status'] == '1'
        end
      end
    end
    item_listed_for_sale
  end

  def fetch_database_inventory
    SellableInventory.inventory(@steam_account).where(listed_for_sale: false, market_type: 'market_csgo')
    # response = MarketcsgoService.fetch_inventory(@steam_account)
    # if response['success']
    #   item_response = response['items']
    # else
    #   item_response = []
    # end
    # item_response
  end
end
