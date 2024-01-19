class UpdateAuctionItemJob
	include Sidekiq::Job
    
	def perform
		p "<============= Update Auction Items Job started... ================>"
		@users = User.all
		@users.each do |user|
			begin
				CsgoempireService.new(user).items_bid_history
			rescue => e
					puts "Something went wrong with -> Auction Update <- for user #{user.email}: #{e} in Auction Items Updation Job"
			end
		end
	end
end