class InventoriesController < ApplicationController
  def index
    @active_steam_account = SteamAccount.find_by(active: true, user_id: current_user.id)
    @inventories = Inventory.where(steam_id: @active_steam_account&.steam_id)
    respond_to do |format|
      format.html { render :index } # Assuming your HTML template is named index.html.erb
      format.json { render json: @inventories }
    end
  end
end
