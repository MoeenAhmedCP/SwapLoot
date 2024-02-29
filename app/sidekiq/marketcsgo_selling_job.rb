class MarketcsgoSellingJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform(*steam_account_id)
    p '<=========== Selling Job started ===================>'
    @steam_account = SteamAccount.find_by(id: steam_account_id)
    MarketcsgoSellingService.new(@steam_account).sell_market_csgo
  end
end
