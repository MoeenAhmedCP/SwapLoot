class MissingItemsService < ApplicationService
  include HTTParty
  BASE_URL = CSGO_EMPIRE_BASE_URL

  def initialize(user)
    @user = user
    @active_steam_account = @user.active_steam_account
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end

  def missing_items
    return [] if @active_steam_account.nil?
    url = CSGO_EMPIRE_BASE_URL + '/trading/user/inventory'
    response = self.class.get(url, headers: @headers)

    if response['success'] == false
      report_api_error(response, [self&.class&.name, __method__.to_s])
    else
      if response['items']
        api_inventory_item = response['items'].pluck('id')
        Inventory.where.not(item_id: api_inventory_item).where(steam_id: @active_steam_account.steam_id, sold_at: nil)
      end
    end
  end
end
