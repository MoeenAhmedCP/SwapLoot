class CsgoSellingJob
    include Sidekiq::Job
    
    def perform(*steam_account_id)
        @steam_account =  SteamAccount.find_by(id: steam_account_id )
        CsgoempireSellingService.new(@steam_account).sell_csgoempire
        p "Selling Job started"
    end
end