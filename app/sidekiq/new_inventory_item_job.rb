class NewInventoryItemJob
  include Sidekiq::Job
  sidekiq_options retry: false
  include HTTParty

  def perform(item, steam_account_id)
    p "<=========== Add Inventory Job ===================>"
    steam_account = SteamAccount.find(steam_account_id)
    inventory_items = Inventory.where(steam_id: steam_account.steam_id)
    @headers = { 'Authorization' => "Bearer #{steam_account.csgoempire_api_key}" }
    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: @headers)
    api_response_data = response["data"]
    items_not_in_inventory = api_response_data.reject { |api_item| inventory_items.any? { |inventory_item| api_item['id'].to_s == inventory_item.item_id } }
    matching_items = items_not_in_inventory.select { |api_item| api_item['market_name'] == item["data"]["item"]["market_name"] }
    matching_items.each do |items|
      inventory = Inventory.create(item_id: items["id"], market_name: items["market_name"], tradable: items["tradable"], steam_id: steam_account.steam_id)
      inventory.update(market_price: (item["data"]["item"]["market_value"] * 0.614))
    end
  end
end
