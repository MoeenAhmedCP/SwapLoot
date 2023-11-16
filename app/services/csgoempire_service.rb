class CsgoempireService
  include HTTParty

  BASE_URL = 'https://csgoempire.com/api/v2'

  def initialize(current_user)
    @current_user = current_user
    @active_steam_account = SteamAccount.find_by(active: true, user_id: @current_user.id)
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end

  def fetch_balance
    response = self.class.get(BASE_URL + '/metadata/socket', headers: @headers)
    response['user']['balance'].to_f / 100 if response['user']
  end

  def fetch_user_data
    response = self.class.get(BASE_URL + '/metadata/socket', headers: @headers)
    response['user'] if response['user']
  end

  def fetch_active_trade
    self.class.get(BASE_URL + '/trading/user/trades', headers: @headers)
  end

end
