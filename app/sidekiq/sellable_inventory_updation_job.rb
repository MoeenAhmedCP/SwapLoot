class SellableInventoryUpdationJob
	include Sidekiq::Job
	sidekiq_options retry: false
	
	def perform
		p "<============= Sellable Inventory Updation Database Job started... ================>"
		@users = User.all
		@users.each do |user|
			user.steam_accounts.each do |steam_account|
				begin
					p "<============= Fetching CSGOEMpire Inventory ================>"
					tradeable_inventory_to_save = SellableInventoryUpdationService.new(steam_account).update_sellable_inventory("csgo_empire")
					tradeable_inventory_to_save.each do |item|
						begin
							SellableInventory.find_or_create_by!(
							item_id: item["id"]
							) do |sellable_inventory|
								sellable_inventory.market_name = item["market_name"]
								sellable_inventory.market_price = item["market_value"].to_f / 100 * 0.614
								sellable_inventory.steam_id = steam_account.steam_id
								sellable_inventory.listed_for_sale = false
								sellable_inventory.market_type = "csgo_empire"
							end
						rescue => e
							puts "Sellable Inventory can not be created due to: #{e}"
						end
					end
				rescue => e
					puts "Something went wrong with Fetch inventory API CSGOEmpire for user #{user.email}: #{e} in Sellable Inventory Updation Job"
				end

				begin
					p "<============= Fetching Waxpeer Inventory ================>"
					tradeable_inventory_to_save = SellableInventoryUpdationService.new(steam_account).update_sellable_inventory("waxpeer")
					tradeable_inventory_to_save.each do |item|
						begin
							SellableInventory.find_or_create_by!(
							item_id: item["item_id"]
							) do |sellable_inventory|
								sellable_inventory.market_name = item["name"]
								sellable_inventory.market_price = item["steam_price"]["average"]
								sellable_inventory.steam_id = steam_account.steam_id
								sellable_inventory.listed_for_sale = false
								sellable_inventory.market_type = "waxpeer"
							end
						rescue => e
							puts "Sellable Inventory can not be created due to: #{e}"
						end
					end
				rescue => e
					puts "Something went wrong with Fetch inventory API WAXPEER for user #{user.email}: #{e} in Sellable Inventory Updation Job"
				end
			end
		end
	end
end
