class InventoriesController < ApplicationController
  before_action :fetch_inventory, only: %i[index]

  def index
    @active_steam_account = current_user.active_steam_account
    if params["tradable"] == "true"
      @inventories = Inventory.tradable_steam_inventories(@active_steam_account)
    elsif params["tradable"] == "false"
      @inventories = Inventory.non_tradable_steam_inventories(@active_steam_account)
    else
      @inventories = Inventory.where(steam_id: @active_steam_account.steam_id)
    end

    begin
      @missing_items = MissingItemsService.new(current_user).missing_items
    rescue StandardError => e
      flash[:notice] = "Something went wrong: #{e.message}"
    end
    respond_to do |format|
      format.html
      format.js
    end
    @total_market_price = Inventory.sum(:market_price)
  end

  private

  def fetch_inventory
    Inventory.fetch_inventory_for_user(current_user)
  end
end
