class InventoriesController < ApplicationController
  before_action :fetch_inventory, only: %i[index]

  def index
    @steam_accounts = SteamAccount.where(user_id: current_user.id)
    @active_steam_account = current_user.active_steam_account
    @inventories = Inventory.steam_inventories(@active_steam_account)
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
