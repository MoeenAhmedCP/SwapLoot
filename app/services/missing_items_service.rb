class MissingItemsService
  include HTTParty
  BASE_URL = 'https://market.csgo.com/api/v2'

  def initialize(user)
    @active_steam_account = user.steam_accounts.where(active: true)&.first #use scope for active steam account
  end

  def missing_items
    return [] if @active_steam_account.nil?
    url = "#{BASE_URL}/my-inventory?key=#{@active_steam_account.market_csgo_api_key}"
    response = self.class.get(url)
    api_inventory_item = response['items'].pluck("id")
    missing_items = Inventory.where.not(item_id: api_inventory_item).where(sold_at: nil)
  end
end
