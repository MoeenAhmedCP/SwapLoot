class SteamAccountsController < ApplicationController
  before_action :set_steam_account, only: %i[edit update destroy show_api_keys edit_api_keys]
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
      flash[:notice] = response_message
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

  def show_api_keys
    @success = check_password?
    if current_user.discord_bot_token.present? && current_user.discord_channel_id.present?
      @success ? notify_discord("#{current_user.email} successfully accessed API keys") :  notify_discord("#{current_user.email} tried to access API keys")
    end
    respond_to do |format|
      format.js
    end
  end

  def edit_api_keys
    @success = check_password?
    if current_user.discord_bot_token.present? && current_user.discord_channel_id.present?
      @success ? notify_discord("#{current_user.email} successfully accessed API keys") :  notify_discord("#{current_user.email} tried to edit API keys")
    end
    respond_to do |format|
      format.js
    end
  end

  private

  def check_password?
    current_user.valid_password?(params[:current_password])
  end

  def set_steam_account
    @steam_account = SteamAccount.find_by(id: params[:id])
  end


  def steam_account_params
    params.require(:steam_account).permit(:steam_id, :unique_name,:steam_web_api_key, :waxpeer_api_key, :csgoempire_api_key, :market_csgo_api_key, :price_empire_api_key)
  end

  def set_steam_account_filters
    if @steam_account.present?
      TradeService.create(steam_account_id: @steam_account.id)
      SellingFilter.create(steam_account_id: @steam_account.id)
      BuyingFilter.create(steam_account_id: @steam_account.id)
    end
  end

  def notify_discord(message)
    begin
      bot = Discordrb::Bot.new(token: current_user.discord_bot_token)
      channel = bot.channel(current_user.discord_channel_id)
      channel.send_message(message)
    rescue StandardError => e
      @notification = current_user.notifications.create(title: "Discord Login", body: "User is unauthorized", notification_type: "Login")
    end
  end

  def response_message
    message = []
    message << 'Steam account was successfully added.'
    message << 'CSGOEmpire API Key is invalid.' if @steam_account.csgoempire_api_key.nil?
    message << 'WAXPEER API Key is invalid.' if @steam_account.waxpeer_api_key.nil?
    message << 'Market.CSGO API Key is invalid.' if @steam_account.market_csgo_api_key.nil?
    message.join(' ')
  end
end
