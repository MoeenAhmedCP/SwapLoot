class InventoriesController < ApplicationController

  def index
    per_page = 15
    steam_ids = @active_steam_account.respond_to?(:each) ? @active_steam_account.map(&:steam_id) : [@active_steam_account.steam_id]
    if params["refresh"].present?
      fetch_inventory
    end
    
    inventories = Inventory.where(sold_at: nil, steam_id: steam_ids, market_type: "csgo_empire")
    inventories = inventories.tradable_steam_inventories(@active_steam_account) if params["tradable"] == "true"
    inventories = inventories.non_tradable_steam_inventories(@active_steam_account) if params["tradable"] == "false"
    inventories = inventories.where(steam_id: steam_ids) if steam_ids.present?
    @q_inventories = inventories.ransack(params[:inventory_search])
    @inventories = @q_inventories.result.order(market_price: :DESC).paginate(page: params[:page], per_page: per_page)
    @q_sellable_inventory = SellableInventory.where(steam_id: steam_ids).ransack(params[:sellable_inventory_search])
    @sellable_inventory = @q_sellable_inventory.result.order(market_price: :DESC).paginate(page: params[:sellable_inventory_page], per_page: per_page)
    @total_market_price = @q_inventories.result.sum(:market_price).round(3)
    sellable_inventory_result = @q_sellable_inventory.result.sum { |item| item.market_price.to_f }
    @total_market_price_sellable_inventory = sellable_inventory_result.round(2)
    waxpeer_inventories = Inventory.where(sold_at: nil, steam_id: steam_ids, market_type: "waxpeer")
    @q_waxpeer_inventory = waxpeer_inventories.ransack(params[:waxpeer_inventory_search])
    @waxpeer_inventory = @q_waxpeer_inventory.result.order(market_price: :DESC).paginate(page: params[:waxpeer_inventory_page], per_page: per_page)
    waxpeer_inventory_result = @waxpeer_inventory.sum { |item| item.market_price.to_f }
    @total_market_price_waxpeer_inventory = waxpeer_inventory_result.round(2)

    missing_item_service
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def missing_item_service
    begin
      @missing_items = MissingItemsService.new(current_user).missing_items
    rescue StandardError => e
      flash[:notice] = "Something went wrong: #{e.message}"
    end
  end

  def fetch_inventory
    Inventory.fetch_inventory_for_user(current_user)
  end
end
