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
    price_empire_response_items = fetch_items_from_pirce_empire
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

  def sell_csgoempire
    matching_items = find_matching_data
    unless matching_items
      sell_csgoempire
    end
    if fetch_items_from_pirce_empire.present?
      items_to_deposit = matching_items.map do |item|
        if item["price"] > (item["price_in_dollar"] + ((item["price_in_dollar"] * @steam_account.selling_filter.min_profit_percentage) / 100 ).round(2))
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

    # Items list from waxpeer that were not found on PriceEmpire
    # @inventory = fetch_database_inventory
    # remaining_items = @inventory&.reject { |inventory_item| matching_items.any? { |matching_item| matching_item["id"] == inventory_item.item_id && matching_item["name"] == inventory_item.market_name } }
    # if remaining_items.any?
    #   filtered_items_for_deposit = []
    #   remaining_items.each do |item|
    #     suggested_items = waxpeer_suggested_prices
    #     result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
    #     item_price = SellableInventory.find_by(item_id: item[:item_id]).market_price
    #     lowest_price = (result_item['lowest_price'].to_f / 1000 / 0.614).round(2)
    #     minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 )).round(2)
    #     if result_item && lowest_price > minimum_desired_price
    #       filtered_items_for_deposit << JSON.parse(item.to_json).merge(:lowest_price => result_item["lowest_price"])
    #     end
    #   end
    #   remaining_items_to_deposit = filtered_items_for_deposit.map { |filtered_item| { "id"=> filtered_item["item_id"], "coin_value"=> calculate_pricing(filtered_item) } }
    #   deposit_items_for_sale(remaining_items_to_deposit) if remaining_items_to_deposit.any?
    # end
  end

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

  def find_matching_items(response_items, inventory)
    matching_items = []
    inventory.each do |inventory_item|
      item_found_from_price_empire = response_items.find_by(item_name: inventory_item['market_hash_name'])
      if item_found_from_price_empire && item_found_from_price_empire["buff"].present?
        buff_price = item_found_from_price_empire["buff"]["price"] + (item_found_from_price_empire["buff"]["price"] * 0.1)
        matching_item = {
          'id' => inventory_item['id'],
          'price' => buff_price * 10,
          'cur' => 'USD',
          'price_in_dollar' => inventory_item['market_price'] * 100, # /0.614 dollar value bought
        }
        matching_items << matching_item
      else
        next
      end
    end
    return matching_items
  end

  def deposit_items_for_sale(items)
    batch_process_sale_item(items)
    # sell_csgoempire
  end

  def batch_process_sale_item(items)
    items.each do |item|
      batch_hash = {
        key: "#{@steam_account&.market_csgo_api_key}",
        id: item['id'],
        price: item['price'],
        cur: item['cur']
      }
      response = HTTParty.post(MARKET_CSGO_BASE_URL + '/add-to-sale', query: batch_hash)

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

  def fetch_items_from_pirce_empire
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

  def fetch_database_inventory
    #SellableInventory.inventory(@steam_account).where(listed_for_sale: false)
    response = MarketcsgoService.fetch_inventory(@steam_account)
    if response['success']
      item_response = response['items']
    else
      item_response = []
    end
    item_response
  end
end
