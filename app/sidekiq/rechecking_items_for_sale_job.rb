class RecheckingItemsForSaleJob
	include Sidekiq::Job
	
	def perform
		puts "Rechecking Items for sale Job started..."
		User.all.each do |user|
			user.steam_accounts.each do |steam_account|
				if steam_account.trade_service.selling_job_id.present? && steam_account.trade_service.selling_status
					selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
					steam_account.trade_service.update(selling_job_id: selling_job_id)
				end
			end
		end
	end
end