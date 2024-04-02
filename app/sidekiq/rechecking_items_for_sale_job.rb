class RecheckingItemsForSaleJob
	include Sidekiq::Job
	sidekiq_options retry: false
	
	def perform
		User.all.each do |user|
			user.steam_accounts.each do |steam_account|
				if steam_account.trade_services.csgoempire_trade_service&.selling_job_id.present? && steam_account.trade_services.csgoempire_trade_service&.selling_status
					puts "Rechecking Items for sale Job started fro CSGOEmpire..."
					selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
					steam_account.trade_services.csgoempire_trade_service.update(selling_job_id: selling_job_id)
				end
				if steam_account.trade_services.waxpeer_trade_service&.selling_job_id.present? && steam_account.trade_services.waxpeer_trade_service&.selling_status
					puts "Rechecking Items for sale Job started fro Waxpeer..."
					selling_job_id = WaxpeerSellingJob.perform_async(steam_account.id)
					steam_account.trade_services.waxpeer_trade_service.update(selling_job_id: selling_job_id)
				end
				if steam_account.trade_services.market_csgo_trade_service&.selling_job_id.present? && steam_account.trade_services.market_csgo_trade_service&.selling_status
					puts "Rechecking Items for sale Job started fro Market.CSGO ..."
					selling_job_id = MarketcsgoSellingJob.perform_async(steam_account.id)
					steam_account.trade_services.market_csgo_trade_service.update(selling_job_id: selling_job_id)
				end
			end
		end
	end
end