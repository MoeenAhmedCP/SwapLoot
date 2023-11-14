class CsgoempireService
  include HTTParty

  BASE_URL = 'https://csgoempire.com/api/v2'

  def fetch_my_inventory
    @headers = set_headers
    response = self.class.get(BASE_URL + '/trading/user/inventory', headers: @headers)

    save_inventory(response)
  end

  def fetch_balance
    @headers = set_headers
    response = self.class.get(BASE_URL + '/metadata/socket', headers: @headers)    
    response['user']['balance'].to_f / 100 if response['user']
  end

  def fetch_active_trade
    @headers = set_headers
    response = self.class.get(BASE_URL + '/trading/user/trades', headers: @headers)
  end

  def save_inventory(res)
    @active_steam_account = SteamAccount.find_by(active: true)
    if @active_steam_account
      res['data']&.each do |item|
        Inventory.find_or_create_by(item_id: item['asset_id'], steam_id: @active_steam_account&.steam_id, market_name: item['market_name'], market_price: item['market_value'], tradable: item['tradable'])
      end
    end
  end

  def set_headers
    @active_steam_account = SteamAccount.find_by(active: true)
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end
end
