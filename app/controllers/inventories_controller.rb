class InventoriesController < ApplicationController

  def index
    per_page = 15
    steam_ids = @active_steam_account.respond_to?(:each) ? @active_steam_account.map(&:steam_id) : [@active_steam_account.steam_id]
    if params["refresh"].present?
      fetch_inventory
    end

    if params["tradable"] == "true"
      inventories = Inventory.tradable_steam_inventories(@active_steam_account)
    elsif params["tradable"] == "false"
      inventories = Inventory.non_tradable_steam_inventories(@active_steam_account)
    else
      inventories = Inventory.where(steam_id: steam_ids)
    end

    @q_inventories = inventories.ransack(params[:inventory_search])
    @inventories = @q_inventories.result.paginate(page: params[:page], per_page: per_page)

    @q_sellable_inventory = SellableInventory.where(steam_id: steam_ids).ransack(params[:sellable_inventory_search])
    @sellable_inventory = @q_sellable_inventory.result.paginate(page: params[:sellable_inventory_page], per_page: per_page)

    @total_market_price = @q_inventories.result.sum(:market_price).round(3)

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
