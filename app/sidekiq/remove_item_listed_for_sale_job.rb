class RemoveItemListedForSaleJob
    include Sidekiq::Job
    
    def perform(steam_account_id)
        p "<=========== Removing Items Listed for Sale Job started ===================>"
        @steam_account =  SteamAccount.find_by(id: steam_account_id )
        removed_listed_items_response = CsgoempireSellingService.new(@steam_account).remove_listed_items_for_sale
        unless removed_listed_items_response
            RemoveItemListedForSaleJob.perform_in(1.minute, steam_account_id)
        end
    end
end