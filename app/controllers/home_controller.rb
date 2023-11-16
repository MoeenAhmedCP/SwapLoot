class HomeController < ApplicationController
  before_action :fetch_csgo_empire_balance, :fetch_csgo_market_balance, :fetch_waxpeer_balance,
                :fetch_active_trade, :fetch_inventory, only: %i[index]

  def index
    @active_steam_account = SteamAccount.find_by(active: true, user_id: current_user.id)
    @inventories = Inventory.where(steam_id: @active_steam_account&.steam_id).order(market_price: :desc)
    @steam_accounts = SteamAccount.where(user_id: current_user.id)
  end

  def active_trades_reload
    fetch_active_trade
    respond_to do |format|
      format.js
    end
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
    csgo_service = CsgoempireService.new(current_user)
    @csgo_empire_balance = csgo_service.fetch_balance
  end

  def fetch_csgo_market_balance
    marketcsgo_service = MarketcsgoService.new(current_user)
    @csgo_market_balance = marketcsgo_service.fetch_balance
  end

  def fetch_waxpeer_balance
    waxpeer_service = WaxpeerService.new(current_user)
    @waxpeer_balance = waxpeer_service.fetch_balance
  end

  def fetch_active_trade
    waxpeer_service = WaxpeerService.new(current_user)
    @active_trades = waxpeer_service.fetch_active_trade
  end

  def fetch_inventory
    marketcsgo_service = MarketcsgoService.new(current_user)
    marketcsgo_service.fetch_my_inventory
  end
end
