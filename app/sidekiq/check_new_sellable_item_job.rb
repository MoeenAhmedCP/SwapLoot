class CheckNewSellableItemJob
	include Sidekiq::Job
	sidekiq_options retry: false
	
	def perform
		p "<============= Sellable Inventory Updation Database Job started... ================>"
		@users = User.all
		@users.each do |user|
			user.steam_accounts.each do |steam_account|
				fetch_sellable_inventory(steam_account)
			end
		end
	end

	def fetch_sellable_inventory(steam_account)
		if steam_account.csgoempire_api_key.present?
			begin
				p "<============= Fetching CSGOEMpire Inventory for #{steam_account.unique_name} ================>"
				tradeable_inventory_to_save = SellableInventoryUpdationService.new(steam_account).update_sellable_inventory("csgoempire")
				tradeable_inventory_to_save&.each do |item|
          new_item = SellableInventory.find_by(item_id: item["id"], market_type: "csgoempire")
          unless new_item
            price_empire_item = PriceEmpire.find_by(item_name: item['market_name'])
            if price_empire_item.present? && price_empire_item['buff_avg7'].present?
              item_price = price_empire_item['buff_avg7']['price'] < 0 ? 0 : (((price_empire_item['buff_avg7']['price'] * 0.95).to_f / 100) * 0.614).round(2)
            else
              item_price = item['market_value'] < 0 ? 0 : ((item['market_value'].to_f / 100) * 0.614).round(2)
            end
            begin
              SellableInventory.create!(
              item_id: item["id"],
              market_name: item["market_name"],
              market_price: item_price,
              steam_id: steam_account.steam_id,
              listed_for_sale: false,
              market_type: "csgoempire"
            )
            rescue => e
              puts "Sellable Inventory can not be created for CSGOEmpire due to: #{e}"
            end
          end
				end
			rescue => e
				puts "Something went wrong with Fetch inventory API CSGOEmpire for user #{user.email}: #{e} in Sellable Inventory Updation Job"
			end
		end
	
		if steam_account.waxpeer_api_key.present?
			begin
				p "<============= Fetching Waxpeer Inventory for #{steam_account.unique_name} ================>"
				tradeable_inventory_to_save = SellableInventoryUpdationService.new(steam_account).update_sellable_inventory("waxpeer")
				tradeable_inventory_to_save&.each do |item|
          new_item = SellableInventory.find_by(item_id: item["item_id"], market_type: "waxpeer")
          unless new_item
            price_empire_item = PriceEmpire.find_by(item_name: item['name'])
            if price_empire_item.present? && price_empire_item['buff_avg7'].present?
              item_price = price_empire_item['buff_avg7']['price'] < 0 ? 0 : ((price_empire_item['buff_avg7']['price'] * 0.95)/100.to_f).round(2)
            else
              item_price = item["steam_price"]["current"] < 0 ? 0 : (item["steam_price"]["current"]/1000.to_f).round(2)
            end
            begin
              SellableInventory.create!(
                item_id: item["item_id"],
                market_name: item["name"],
                market_price: item_price,
                steam_id: steam_account.steam_id,
                listed_for_sale: false,
                market_type: "waxpeer"
              )
            rescue => e
              puts "Sellable Inventory can not be created for Waxpeer due to: #{e}"
            end
          end
				end
			rescue => e
				puts "Something went wrong with Fetch inventory API WAXPEER for user #{user.email}: #{e} in Sellable Inventory Updation Job"
			end
		end
	
		if steam_account.market_csgo_api_key.present?
			begin
				p "<============= Fetching MarketCSGO Inventory for #{steam_account.unique_name} ================>"
				tradeable_inventory_to_save = SellableInventoryUpdationService.new(steam_account).update_sellable_inventory("market_csgo")
				tradeable_inventory_to_save&.each do |item|
          new_item = SellableInventory.find_by(item_id: item["id"], market_type: "market_csgo")
          unless new_item
            price_empire_item = PriceEmpire.find_by(item_name: item['market_hash_name'])
            if price_empire_item.present? && price_empire_item['buff_avg7'].present?
              item_price = price_empire_item['buff_avg7']['price'] < 0 ? 0 : ((price_empire_item['buff_avg7']['price'] * 0.95)/100.to_f).round(2)
            else
              item_price = item["market_price"] < 0 ? 0 : item["market_price"]
            end
            begin
              SellableInventory.create!(
              item_id: item["id"],
              market_name: item["market_hash_name"],
              market_price: item_price,
              steam_id: steam_account.steam_id,
              listed_for_sale: false,
              market_type: "market_csgo"
            ) 
            rescue => e
              puts "Sellable Inventory can not be created for MarketCSGO due to: #{e}"
            end
          end
				end
			rescue => e
				puts "Something went wrong with Fetch inventory API MARKET.CSGO for user #{user.email}: #{e} in Sellable Inventory Updation Job"
			end
		end
	end
end
