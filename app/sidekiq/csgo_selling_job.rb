class CsgoSellingJob
    include Sidekiq::Job
    sidekiq_options queue: 'csgoempire_selling', retry: false
    
    def perform(*steam_account_id)
        p "<===========CSGOEmpire Selling Job started ===================>"
        @steam_account =  SteamAccount.find_by(id: steam_account_id )
        CsgoempireSellingService.new(@steam_account).sell_csgoempire
    end
end