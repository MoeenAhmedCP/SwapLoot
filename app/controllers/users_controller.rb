class UsersController < ApplicationController
  include HTTParty

  BASE_URL_CSGOEMPIRE = 'https://csgoempire.com/api/v2'
  BASE_URL_WAXPEER = 'https://api.waxpeer.com/v1'
  BASE_URL_MARKETCSGO = 'https://market.csgo.com/api/v2'

  def show
    @user_accounts_data = fetch_user_accounts_data
  end

  private

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

      user_account_data = {
        steam_account: steam_account,
        data: JSON.parse(response.body)['user'],
        waxpeer_balance: fetch_balance_waxpeer(steam_account),
        market_csgo_balance: fetch_balance_marketcsgo(steam_account)
      }

      user_accounts_data << user_account_data
    end

    user_accounts_data
  end
end
