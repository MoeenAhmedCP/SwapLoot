class HomeController < ApplicationController
  before_action :fetch_csgo_empire_balance, :fetch_csgo_market_balance, :fetch_waxpeer_balance,
                :fetch_active_trade, :fetch_inventory, only: %i[index]

  def index
    @active_steam_account = SteamAccount.find_by(active: true)
    @inventories = Inventory.where(steam_id: @active_steam_account&.steam_id)
    @steam_accounts = SteamAccount.all
  end

  def update_active_account
    selected_steam_id = params[:steam_id]
    SteamAccount.transaction do
      SteamAccount.update_all(active: false)
      account = SteamAccount.find_by(steam_id: selected_steam_id)
      account.update(active: true) if account.present?
    end
    redirect_to root_path
  end

  private

  def fetch_csgo_empire_balance
    @csgo_empire_balance = CsgoempireService.new.fetch_balance
  end

  def fetch_csgo_market_balance
    @csgo_market_balance = MarketcsgoService.new.fetch_balance
  end

  def fetch_waxpeer_balance
    @waxpeer_balance = WaxpeerService.new.fetch_balance
  end

  def fetch_active_trade
    @active_trades = WaxpeerService.new.fetch_active_trade
  end

  def fetch_inventory
    WaxpeerService.new.fetch_my_inventory
    MarketcsgoService.new.fetch_my_inventory
    CsgoempireService.new.fetch_my_inventory
  end
end
