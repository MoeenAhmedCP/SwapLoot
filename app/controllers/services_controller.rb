class ServicesController < ApplicationController
  before_action :set_steam_account, only: %i[selling_service]

  def index
    @steam_accounts = current_user.steam_accounts
  end

  def trigger_service; end

  private

  def set_steam_account
    @steam_account = SteamAccount.find_by(steam_id: params[:steam_id])
  end
end
