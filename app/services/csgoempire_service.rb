class CsgoempireService
  include HTTParty

  BASE_URL = 'https://csgoempire.com/api/v2'

  def fetch_balance
    @headers = set_headers
    response = self.class.get(BASE_URL + '/metadata/socket', headers: @headers)    
    response['user']['balance'].to_f / 100 if response['user']
  end

  def fetch_active_trade
    @headers = set_headers
    self.class.get(BASE_URL + '/trading/user/trades', headers: @headers)
  end

  def set_headers
    @active_steam_account = SteamAccount.find_by(active: true)
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end
end
