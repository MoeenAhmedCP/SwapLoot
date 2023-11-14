class InventoriesController < ApplicationController
  def index
    @active_steam_account = SteamAccount.find_by(active: true) 
    @inventories = Inventory.where(steam_id: @active_steam_account&.steam_id)
  end
end
