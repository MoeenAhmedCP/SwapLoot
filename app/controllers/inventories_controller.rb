class InventoriesController < ApplicationController
  before_action :fetch_inventory, only: %i[index]

  def index
    if params["tradable"] == "true"
      @inventories = Inventory.tradable_steam_inventories(@active_steam_account)
    elsif params["tradable"] == "false"
      @inventories = Inventory.non_tradable_steam_inventories(@active_steam_account)
    else
      if @active_steam_account.respond_to?(:each)
        @inventories = Inventory.where(steam_id: @active_steam_account.map(&:steam_id))
      else
        @inventories = Inventory.where(steam_id: @active_steam_account.steam_id)
      end
    end
    @total_market_price = @inventories.sum(:market_price).round(3)
    begin
      @missing_items = MissingItemsService.new(current_user).missing_items
    rescue StandardError => e
      flash[:notice] = "Something went wrong: #{e.message}"
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def fetch_inventory
    Inventory.fetch_inventory_for_user(current_user)
  end
end
