class MarketcsgoService
  include HTTParty

  BASE_URL = 'https://market.csgo.com/api/v2'

  def fetch_my_inventory
    @active_steam_account = SteamAccount.find_by(active: true)
    params = {
      key: "#{@active_steam_account&.market_csgo_api_key}"
    }
    response = self.class.get(BASE_URL + '/my-inventory', query: params)

    save_inventory(response)
  end

  def fetch_balance
    params = {
      key: "#{ENV['MARKETCSGO_KEY']}"
    }
    res = self.class.get(BASE_URL + 'get-money', query: params)
    res['money'] if res
  end

  def save_inventory(res)
    @active_steam_account = SteamAccount.find_by(active: true)
    if @active_steam_account
      res['items']&.each do |item|
        Inventory.find_or_create_by(item_id: item['id'], steam_id: @active_steam_account&.steam_id, market_name: item['market_hash_name'], market_price: item['market_price'], tradable: item['tradable'])
      end
    end
  end
end
