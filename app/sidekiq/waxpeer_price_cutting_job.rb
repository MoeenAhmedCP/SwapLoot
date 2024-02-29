class WaxpeerPriceCuttingJob
    include Sidekiq::Job
    sidekiq_options retry: false
    
    def perform(steam_account_id)
        p "<============= Price Cutting Job started... ================>"
        @steam_account =  SteamAccount.find_by(id: steam_account_id)
        WaxpeerSellingService.new(@steam_account).waxpeer_price_cutting
    end
end