class RemoveWaxpeerItemsFromListingJob
    include Sidekiq::Job
    sidekiq_options retry: false
    
    def perform(steam_account_id)
        p "<=========== Removing Items Listed from Sale Waxpeer Job started ===================>"
        @steam_account =  SteamAccount.find_by(id: steam_account_id )
        removed_listed_items_response = WaxpeerSellingService.new(@steam_account).remove_all_listings
    end
end