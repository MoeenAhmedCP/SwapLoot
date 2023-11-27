class HomeController < ApplicationController
  include HomeControllerConcern

  def index
    @active_steam_account = User.active_steam_account(current_user)
    @steam_accounts = SteamAccount.where(user_id: current_user.id)
  end

  def fetch_user_data
    steam_account = User.active_steam_account(current_user)
    
    if steam_account
      csgo_service_response = CsgoempireService.new(current_user).fetch_user_data(steam_account)

      respond_to do |format|
        format.js { render json: csgo_service_response }
      end
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
      SteamAccount.update_all(active: false)
      account = current_user.steam_accounts.find_by(steam_id: selected_steam_id)
      account.update(active: true) if account.present?
    end
    redirect_to root_path
  end

  def refresh_balance
    respond_to do |format|
      format.js
    end
  end
end
