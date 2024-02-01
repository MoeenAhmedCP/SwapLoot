class SellableInventoryUpdationService < ApplicationService
	include HTTParty

	def initialize(steam_account)
		@steam_account = steam_account
	end

	# function is to update sellable inventory from waxpeer API to update/BULK Insert database after 15 minutes
	def update_sellable_inventory
		headers = { 'Authorization' => "Bearer #{@steam_account.csgoempire_api_key}" }
		begin
			inventory_response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers)
			if inventory_response['success'] == false
				report_api_error(inventory_response, [self&.class&.name, __method__.to_s]) 
			else
				tradeable_inventory_to_save = inventory_response["data"].select { |item| item["market_value"] != -1 && item["tradable"] == true && item["tradelock"] == false }
			end
		rescue
			puts "Something went wrong with Fetch inventory API.. retrying in 2 minutes"
			SellableInventoryUpdationJob.perform_in(2.hour)
		end
	end
end
  
  