class HomeController < ApplicationController
  include HomeControllerConcern

  def index
    @steam_accounts = SteamAccount.where(user_id: current_user.id)
    @items_sold = @active_steam_account ? SoldItem.where(steam_account: current_user.active_steam_account) : SoldItem.where(steam_account: current_user.steam_accounts)
  end

  def fetch_all_steam_accounts
    accounts_data = []
    steam_accounts = current_user.steam_accounts

    steam_accounts.each do |account|
      csgo_service_response = CsgoempireService.fetch_user_data(account)
      accounts_data << { 'user_data' => csgo_service_response, 'account_id' => account.id }
    end

    respond_to do |format|
      format.js { render json: accounts_data }
    end
  end

  def active_trades_reload
    fetch_active_trade
    respond_to do |format|
      format.js
    end
  end

  def reload_item_listed_for_sale
    fetch_item_listed_for_sale
    respond_to do |format|
      format.js
    end
  end

  def update_active_account
    selected_steam_id = params[:steam_id]
    SteamAccount.transaction do
      current_user.active_steam_account&.update(active: false)
      account = current_user.steam_accounts.find_by(steam_id: selected_steam_id)
      account.update(active: true) if account.present?
    end
    redirect_back(fallback_location: root_path)
  end

  def refresh_balance
    respond_to do |format|
      format.js
    end
  end
end
