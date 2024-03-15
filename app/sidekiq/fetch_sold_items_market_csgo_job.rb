class FetchSoldItemsMarketCsgoJob
	include Sidekiq::Job
	sidekiq_options retry: false
	
	def perform
		p "<============= Fetch Sold Items Market.CSGO Job started... ================>"
		@users = User.all
		@users.each do |user|
            user.steam_accounts&.each do |steam_account|
                begin
                    MarketcsgoService.fetch_sold_item_market_csgo(steam_account)
                rescue
                    "*********    Fetch Sold Items Market.CSGO Job Failed....  **************"
                end
            end
		end
	end
end
