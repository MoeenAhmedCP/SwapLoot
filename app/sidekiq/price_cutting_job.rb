class PriceCuttingJob
    include Sidekiq::Job
    sidekiq_options retry: false
    
    def perform(steam_account_id)
        p "<============= Price Cutting Job started... ================>"
        @steam_account =  SteamAccount.find_by(id: steam_account_id)
        CsgoempireSellingService.new(@steam_account).price_cutting_down_for_listed_items
    end
end