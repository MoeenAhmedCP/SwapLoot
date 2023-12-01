class SteamAccountsController < ApplicationController
  before_action :set_steam_account, only: %i[edit update destroy]
  after_action :set_steam_account_filters, only: %i[create]
  
  def index
    @steam_accounts = current_user.steam_accounts
  end

  def new
    @steam_account = SteamAccount.new
  end

  def create
    @steam_account = current_user.steam_accounts.build(steam_account_params)
    if @steam_account.save
      flash[:notice] = 'Steam account was successfully added.'
      redirect_to steam_accounts_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @steam_account.update(steam_account_params)
      flash[:notice] = 'Steam account was successfully updated.'
      redirect_to steam_accounts_path
    else
      render :edit
    end
  end

  def destroy
    redirect_to steam_accounts_path, notice: 'Steam account was successfully deleted.' if @steam_account.destroy
  end

  private

  def set_steam_account
    @steam_account = SteamAccount.find_by(id: params[:id])
  end

  def steam_account_params
    params.require(:steam_account).permit(:steam_id, :unique_name,:steam_web_api_key, :waxpeer_api_key, :csgoempire_api_key, :market_csgo_api_key, :price_empire_api_key)
  end

  def set_steam_account_filters
    @steam_account = SteamAccount.find_by(steam_id: params["steam_account"]["steam_id"])
    TradeService.create(steam_account_id: @steam_account.id)
    SellingFilter.create(steam_account_id: @steam_account.id)
    BuyingFilter.create(steam_account_id: @steam_account.id)
  end
end
