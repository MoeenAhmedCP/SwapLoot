class SellableInventoryUpdationJob
	include Sidekiq::Job
	
	def perform
		p "<============= Sellable Inventory Updation Database Job started... ================>"
		@users = User.all
		@users.each do |user|
			user.steam_accounts.each do |steam_account|
				begin
					tradeable_inventory_to_save = SellableInventoryUpdationService.new(steam_account).update_sellable_inventory
					tradeable_inventory_to_save.each do |item|
						begin
							SellableInventory.find_or_create_by!(
							item_id: item["id"]
							) do |sellable_inventory|
								sellable_inventory.market_name = item["market_name"]
								sellable_inventory.market_price = item["market_value"].to_f / 100 * 0.614
								sellable_inventory.steam_id = steam_account.steam_id
								sellable_inventory.listed_for_sale = false
							end
						rescue => e
							puts "Sellable Inventory can not be created due to: #{e}"
						end
					end
				rescue => e
					puts "Something went wrong with Fetch inventory API for user #{user.email}: #{e} in Sellable Inventory Updation Job"
				end
			end
		end
	end
end
