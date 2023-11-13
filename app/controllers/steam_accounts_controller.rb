class SteamAccountsController < ApplicationController
  def index
    @steam_accounts = SteamAccount.all
  end

  def new
    @steam_account = SteamAccount.new
  end

  def create
    @steam_account = SteamAccount.new(steam_account_params)

    if @steam_account.save
      redirect_to steam_accounts_path, notice: 'Steam account was successfully added.'
    else
      render :new
    end
  end

  private

  def steam_account_params
    params.require(:steam_account).permit(:steam_id, :unique_name,:steam_web_api_key, :waxpeer_api_key, :csgoempire_api_key, :market_csgo_api_key)
  end
end
