class InventoriesController < ApplicationController
  before_action :fetch_inventory, only: %i[index]

  def index
    @active_steam_account = SteamAccount.active_steam_account(current_user)
    @inventories = Inventory.steam_inventories(@active_steam_account)
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
