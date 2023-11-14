class InventoriesController < ApplicationController
  def index
    #invetory ki values price ki bhi nae converted properly.
    @active_steam_account = SteamAccount.find_by(active: true) 
    @inventories = Inventory.where(steam_id: @active_steam_account&.steam_id).order(market_price: :desc)
  end
end
