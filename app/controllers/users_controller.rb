class UsersController < ApplicationController
  include HTTParty
  before_action :set_user, only: %i[update show]

  BASE_URL_CSGOEMPIRE = 'https://csgoempire.com/api/v2'
  BASE_URL_WAXPEER = 'https://api.waxpeer.com/v1'
  BASE_URL_MARKETCSGO = 'https://market.csgo.com/api/v2'

  def show
    @steam_accounts = current_user.steam_accounts
    @user_accounts_data = fetch_user_accounts_data
  end

  def edit; end

  def update
    @user.update(user_params)
    flash[:notice] = "Discord Credentials updated successfully"
    redirect_to user_path(id: @user)
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
  end

  def user_params
    params.require(:user).permit(:discord_app_id, :discord_channel_id, :discord_bot_token, :ma_file)
  end

  def fetch_balance_waxpeer(steam_account)
    params = {
      api: "#{steam_account.waxpeer_api_key}"
    }
    res = self.class.get(BASE_URL_WAXPEER + '/user', query: params)
    res['user'].present? ? res['user']['wallet'].to_f / 1000 : 0
  end

  def fetch_balance_marketcsgo(steam_account)
    params = {
      key: "#{steam_account.market_csgo_api_key}"
    }
    res = self.class.get(BASE_URL_MARKETCSGO + '/get-money', query: params)
    res['money'] if res
  end

  def fetch_user_accounts_data
    user_accounts_data = []

    steam_accounts = current_user.steam_accounts
    steam_accounts.each do |steam_account|
      headers = { 'Authorization' => "Bearer #{steam_account.csgoempire_api_key}" }
      response = self.class.get(BASE_URL_CSGOEMPIRE + '/metadata/socket', headers: headers)

      if JSON.parse(response.body)['user'].present?
        user_account_data = {
          steam_account: steam_account,
          data: JSON.parse(response.body)['user'],
          waxpeer_balance: fetch_balance_waxpeer(steam_account),
          market_csgo_balance: fetch_balance_marketcsgo(steam_account)
        }

        user_accounts_data << user_account_data
      end
    end

    user_accounts_data
  end
end