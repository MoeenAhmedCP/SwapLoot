class SellableInventoryUpdationService < ApplicationService
	include HTTParty

	def initialize(steam_account)
		@steam_account = steam_account
	end

	# function is to update sellable inventory from waxpeer API to update/BULK Insert database after 15 minutes
	def update_sellable_inventory(type)
		case type
		when "csgoempire"
			headers = { 'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}" }
			begin
				inventory_response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers)
				if inventory_response['success'] == false
					report_api_error(inventory_response, [self&.class&.name, __method__.to_s]) 
				else
					tradeable_inventory_to_save = inventory_response["data"].select { |item| item["market_value"] != -1 && item["tradable"] == true && item["tradelock"] == false }
				end
			rescue
				puts "Something went wrong with Fetch inventory API CSGOEmpire.."
			end
		when "waxpeer"
			headers_waxpeer = { api: @steam_account&.waxpeer_api_key }
			begin
				inventory_response = self.class.get(WAXPEER_BASE_URL + '/get-my-inventory', query: headers_waxpeer)
				if inventory_response['success'] == false
					report_api_error(inventory_response, [self&.class&.name, __method__.to_s]) 
				else
					tradeable_inventory_to_save = inventory_response["items"].select { |item| item["steam_price"]["current"] > 0  }
				end
			rescue
				puts "Something went wrong with Fetch inventory API WAXPEER.."
			end
		when "market_csgo"
			headers = { key: @steam_account.market_csgo_api_key }
			begin
				inventory_response = self.class.get(MARKET_CSGO_BASE_URL + '/my-inventory', query: headers)
				if inventory_response['success'] == false
					report_api_error(inventory_response, [self&.class&.name, __method__.to_s]) 
				else
					tradeable_inventory_to_save = inventory_response["items"].select { |item| item["market_price"] > 0  }
				end
			rescue
				puts "Something went wrong with Fetch inventory API Market.CSGO.."
			end
		end
	end
end
  
  