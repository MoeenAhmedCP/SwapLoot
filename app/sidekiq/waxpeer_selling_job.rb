class WaxpeerSellingJob
    include Sidekiq::Job
    sidekiq_options retry: false
    
    def perform(*steam_account_id)
        p "<=========== Waxpeer Selling Job started ===================>"
        @steam_account =  SteamAccount.find_by(id: steam_account_id )
        WaxpeerSellingService.new(@steam_account).sell_waxpeer_items
    end
end