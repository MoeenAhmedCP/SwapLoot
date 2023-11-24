class CsgoSellingJob < ApplicationJob
    queue_as :default  
  
    def perform(steam_account)
        CsgoempireSellingService.new(steam_account).sell_csgoempire
    end
end