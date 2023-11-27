class MarketcsgoService
  include HTTParty  

  def initialize(current_user)
    @active_steam_account = User.active_steam_account(current_user)
    @params = {
      key: "#{@active_steam_account&.market_csgo_api_key}"
    }
  end

  def fetch_my_inventory
    return if market_csgo_api_key_not_found?

    response = self.class.get(MARKET_CSGO_BASE_URL + '/my-inventory', query: @params)
    save_inventory(response)
  end

  def fetch_balance
    return if market_csgo_api_key_not_found?

    res = self.class.get(MARKET_CSGO_BASE_URL + '/get-money', query: @params)
    res['money'] if res
  end

  def save_inventory(res)
    if @active_steam_account
      res['items']&.each do |item|
        inventory = Inventory.find_by(item_id: item['id'])
        unless inventory.present?
          Inventory.create(item_id: item['id'], steam_id: @active_steam_account&.steam_id, market_name: item['market_hash_name'], market_price: item['market_price'], tradable: item['tradable'])
        end
      end
    end
  end

  def market_csgo_api_key_not_found?
    @active_steam_account&.market_csgo_api_key.blank?
  end
end
