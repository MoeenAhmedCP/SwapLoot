class InventoriesController < ApplicationController

  def index
    per_page = 15
    steam_ids = @active_steam_account.respond_to?(:each) ? @active_steam_account.map(&:steam_id) : [@active_steam_account.steam_id]
    if params["refresh"].present?
      fetch_inventory
    end
    
    sellable_inventories = SellableInventory.where(steam_id: steam_ids)
    sellable_inventories = sellable_inventories.csgoempire_steam_inventories if params["tradable"] == "csgoempire"
    sellable_inventories = sellable_inventories.waxpeer_steam_inventories if params["tradable"] == "waxpeer"
    sellable_inventories = sellable_inventories.market_csgo_steam_inventories if params["tradable"] == "market_csgo"
    @q_sellable_inventory = sellable_inventories.where(steam_id: steam_ids).ransack(params[:sellable_inventory_search])
    
    @sellable_inventory = @q_sellable_inventory.result.order(market_price: :DESC).paginate(page: params[:sellable_inventory_page], per_page: per_page)
    @sellable_inventory = @sellable_inventory.where(market_type: params['sellable_inventory_search']['tradable']) if params['sellable_inventory_search'].present? && params['sellable_inventory_search']["tradable"].present? 
    sellable_inventory_result = @q_sellable_inventory.result.sum { |item| item.market_price.to_f }
    @total_market_price_sellable_inventory = sellable_inventory_result.round(2)
    @missing_items = current_user.active_steam_account.present? ? current_user.active_steam_account.missing_items : MissingItem.where(steam_account_id: current_user.steam_accounts.pluck(:id))
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def fetch_inventory
    # Inventory.fetch_inventory_for_user(current_user)
    SellableInventoryUpdationJob.perform_sync
  end
end
