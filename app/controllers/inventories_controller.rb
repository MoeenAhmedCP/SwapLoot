class InventoriesController < ApplicationController
  def index
    @active_steam_account = SteamAccount.find_by(active: true, user_id: current_user.id)
    @inventories = Inventory.where(steam_id: @active_steam_account&.steam_id)
    respond_to do |format|
      format.html
      format.js
    end
  end
end
