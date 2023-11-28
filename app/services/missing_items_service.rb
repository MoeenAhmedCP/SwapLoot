class MissingItemsService
  include HTTParty
  BASE_URL = 'https://market.csgo.com/api/v2'

  def initialize(user)
    @user = user
    @active_steam_account = current_user.active_steam_account
  end

  def missing_items
    return [] if @active_steam_account.nil?

    url = "#{BASE_URL}/my-inventory?key=#{@active_steam_account.market_csgo_api_key}"
    response = self.class.get(url)
    api_inventory_item = response['items'].pluck('id')
    Inventory.where.not(item_id: api_inventory_item).where(steam_id: @active_steam_account.steam_id, sold_at: nil)
  end
end
