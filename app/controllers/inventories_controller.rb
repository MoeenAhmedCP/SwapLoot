class InventoriesController < ApplicationController
  before_action :fetch_inventory, only: %i[index]

  def index
    @active_steam_account = SteamAccount.find_by(active: true, user_id: current_user.id)
    @inventories = Inventory.where(steam_id: @active_steam_account&.steam_id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def fetch_inventory
    marketcsgo_service = MarketcsgoService.new(current_user)
    marketcsgo_service.fetch_my_inventory
  end
end
