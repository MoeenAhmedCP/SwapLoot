class WaxpeerSellingService < ApplicationService
	include HTTParty
	
	def initialize(steam_account)
		@steam_account = steam_account
		add_proxy
	end

	def headers
		{ api: @steam_account.csgoempire_api_key }
	end

	def add_proxy
		reset_proxy
		if @steam_account.proxy.present?
			proxy = @steam_account.proxy 
			self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
		end
	end

	def sell_waxpeer_items
		matching_items = find_matching_data
		unless matching_items
			sell_csgoempire
		end
		if fetch_items_from_pirce_empire.present?
			items_to_deposit = matching_items.map do |item|
				if item["average"] > (item["bought_price"] + ((item["bought_price"] * @steam_account.selling_filter.min_profit_percentage) / 100 ))
					{ "item_id" => item["id"].to_i, "price" => item["average"] }
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
		@inventory = fetch_database_inventory_waxpeer
		remaining_items = @inventory&.reject { |inventory_item| matching_items.any? { |matching_item| matching_item["id"] == inventory_item.item_id && matching_item["name"] == inventory_item.market_name } }
		if remaining_items.any?
		filtered_items_for_deposit = []
		remaining_items.each do |item|
			suggested_items = waxpeer_suggested_prices
			result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
			item_price = SellableInventory.find_by(item_id: item[:item_id], market_type: "waxpeer").market_price
			lowest_price = result_item['lowest_price']
			minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 ))
			if result_item && lowest_price > minimum_desired_price
			filtered_items_for_deposit << JSON.parse(item.to_json).merge(:lowest_price => result_item["lowest_price"])
			end
		end
		remaining_items_to_deposit = filtered_items_for_deposit.map { |filtered_item| { "item_id"=> filtered_item["item_id"], "price"=> calculate_pricing(filtered_item) } }
		deposit_items_for_sale(remaining_items_to_deposit) if remaining_items_to_deposit.any?
		end
	end


	def waxpeer_price_cutting
		response = fetch_waxpeer_active_trades
		if response['success'] == false
			report_api_error(response, [self&.class&.name, __method__.to_s])
		else
			items_listed_for_sale = []
			items_listed_for_sale = response["items"].map do |deposit|
			{
				item_id: deposit["item_id"],
				market_name: deposit["name"],
				total_value: deposit["total_value"],
				market_value: deposit["price"],
				updated_at: deposit["date"],
				suggested_price: deposit["steam_price"]["average"]
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
				price_cutting_job_id = WaxpeerPriceCuttingJob.perform_in(@steam_account.selling_filter.undercutting_interval.minutes, @steam_account.id)
				#Fix
				# @steam_account.trade_service.update(price_cutting_job_id: price_cutting_job_id)
			end
		end
	end

	def deposit_items_for_sale(items)
    items.each_slice(100) do |batch|
      batch_hash = {"items" => batch}
      response = HTTParty.post(WAXPEER_BASE_URL + '/list-items-steam', query: headers, body: JSON.generate(batch_hash))
      if response.code == SUCCESS_CODE
        batch.each do |item|
          puts "Item: #{item["market_name"]} with ID: #{item["item_id"]} is Listed for sale successfully."
          SellableInventory.find_by(item_id: item["item_id"], market_type: "waxpeer").update(listed_for_sale: true)
        end
        result = JSON.parse(response.body)
      else
        report_api_error(response, [self&.class&.name, __method__.to_s])
        result = API_FAILED
      end
      # Handle rate limiting (One Request can list 100 items and rate limit is 2 requests per 120 seconds for each item_id)
      sleep(2) # Sleep for 2 seconds between each batch
    end
  end

	# Function for Cutting Prices of Items and List them again for sale
	def cutting_price_and_list_again(items)
		filtered_items_for_deposit = []
		items.map do |item|
			item_price = SellableInventory.find_by(item_id: item[:item_id], market_type: "waxpeer").market_price.to_f
			minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 )).round(2)
			minimum_desired_price = minimum_desired_price.round
			current_listed_price = item[:market_value]
			suggested_items = waxpeer_suggested_prices
			result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
			lowest_price = result_item['lowest_price']
			if lowest_price >= minimum_desired_price && lowest_price < current_listed_price
				filtered_items_for_deposit << item.merge(lowest_price: (lowest_price - 1))
			elsif lowest_price < minimum_desired_price && lowest_price < current_listed_price
				filtered_items_for_deposit << item.merge(lowest_price: (minimum_desired_price - 1))
			end
		end
		items_to_deposit = filtered_items_for_deposit.map { |filtered_item| { "item_id"=> filtered_item[:item_id], "price"=> filtered_item[:lowest_price]  } } unless filtered_items_for_deposit.empty?
		# Function to update prices for items after price cutting
    update_prices(items_to_deposit) if items_to_deposit.present?
	end


	# function to cancel deposit of the items listed for sale
  def update_prices(items)
    items.each_slice(50) do |batch|
      batch_hash = {"items" => batch}
      response = HTTParty.post(WAXPEER_BASE_URL + '/edit-items', query: headers, body: JSON.generate(batch_hash))
      if response.code == SUCCESS_CODE
        batch.each do |item|
          puts "Price Updated for Item: #{item["market_name"]} with ID: #{item["item_id"]}"
					SellableInventory.find_by(item_id: item["item_id"], market_type: "waxpeer").update(listed_for_sale: true)
        end
        result = JSON.parse(response.body)
      else
        report_api_error(response, [self&.class&.name, __method__.to_s])
        result = API_FAILED
      end
      # Handle rate limiting (One Request can list 100 items and rate limit is 2 requests per 120 seconds for each item_id)
      sleep(2) # Sleep for 2 seconds between each batch
    end
		waxpeer_price_cutting
  end

	def fetch_inventory
	inventory = fetch_database_inventory_waxpeer
		items_listed_for_sale = fetch_items_listed_for_sale
		unless items_listed_for_sale.empty?
			api_item_ids = items_listed_for_sale["items"].map { |deposit| deposit["item_id"] }
			filtered_response = inventory.reject { |item| api_item_ids.include?(item["id"]) }
			filtered_response
		else
			inventory
		end
	end

	def find_matching_data
		price_empire_response_items = fetch_items_from_pirce_empire
		waxpeer_response_items = waxpeer_suggested_prices if price_empire_response_items.empty?
		inventory = fetch_inventory
		if inventory.present?
			if price_empire_response_items.present?
			matching_items = find_matching_items_from_price_empire(price_empire_response_items, inventory)
			elsif waxpeer_response_items.present?
				matching_items = find_matching_items_from_waxpeer(waxpeer_response_items, inventory)
			end
		else
			matching_items = []
		end
		matching_items
	end

	def find_matching_items_from_waxpeer(waxpeer_response_items, inventory)
    matching_items = []
    inventory.map do |item|
      suggested_items = waxpeer_suggested_prices
      result_item = suggested_items['items'].find { |suggested_item| suggested_item['name'] == item[:market_name] }
      item_price = SellableInventory.find_by(item_id: item[:item_id], market_type: "waxpeer").market_price
      lowest_price = result_item['lowest_price']
      minimum_desired_price = (item_price.to_f + (item_price.to_f * @steam_account.selling_filter.min_profit_percentage / 100 ))
      if result_item && lowest_price > minimum_desired_price
        matching_items << item.attributes.merge(lowest_price: result_item["lowest_price"])
      end
    end
    matching_items.map do |filtered_item|
      { "item_id"=> filtered_item["item_id"], "price"=> calculate_pricing(filtered_item) } 
    end
  end

	# function to fetch matching items between Price Empire API data and Inventory Data
	def find_matching_items_from_price_empire(response_items, inventory)
		matching_items = []
		inventory.each do |inventory_item|
			item_found_from_price_empire = response_items.find_by(item_name: inventory_item.market_name)
			if item_found_from_price_empire
				buff_price = item_found_from_price_empire["buff"]["price"]
				matching_item = {
					'id' => inventory_item.item_id,
					'name' => inventory_item.market_name,
					'average' => (buff_price * 10), # in dollar
					'bought_price' => (inventory_item.market_price.to_i) #saving in dollar from Price Empire or TradeStatus
				}
				matching_items << matching_item
			else
				next
			end
		end
		return matching_items
	end

	def item_ready_to_price_cutting?(updated_at, no_of_minutes)
    estimated_time = updated_at.to_datetime + no_of_minutes.minutes
    estimated_time <= Time.current
  end

	def fetch_waxpeer_active_trades
    HTTParty.get(WAXPEER_BASE_URL + '/list-items-steam', query: headers)
  end

	# Function to fetch Items and Its Prices from different platforms from Price Empire API
  def fetch_items_from_pirce_empire
    response = PriceEmpire.all
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

	# Function for fetch listed items for sale
	def fetch_items_listed_for_sale
		if @steam_account.present?
			return [] if waxpeer_api_key_not_found?
			res = get_listed_items_for_sale
			if res['success'] == false
				report_api_error(res, [self&.class&.name, __method__.to_s])
				response = [{ success: "false", msg: res['msg'] }]
			else
				response = res['items'].present? ? res['items'] : []
			end
		end
		response
	end

	# Fuction for API Call for Items listed for sale from waxpeer
	def get_listed_items_for_sale
		begin
			res = self.class.get(WAXPEER_BASE_URL + '/list-items-steam', query: headers)
		rescue => e
			puts "Unable to fetch Listed items for sale Waxpeer Selling Service due to: #{e.message}"
		end
	end

	# Fetch Waxpeer Inventory from Database
	def fetch_database_inventory_waxpeer
		SellableInventory.where(market_type: "waxpeer", steam_id: @steam_account&.steam_id)
	end

	private

	def waxpeer_api_key_not_found?
    @active_steam_account&.waxpeer_api_key.blank?
  end
end

