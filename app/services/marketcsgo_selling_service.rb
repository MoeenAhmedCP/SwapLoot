class CsgoempireSellingService < ApplicationService
  include HTTParty
  require 'json'

  #initialize steam account fro service
  def initialize(current_user)
    @active_steam_account = current_user.active_steam_account
    @current_user = current_user
    @params = { key: "#{@active_steam_account&.market_csgo_api_key}" }
    add_proxy
  end

  def add_proxy
    reset_proxy
    if @steam_account.proxy.present?
      proxy = @steam_account.proxy 
      self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password
    end
  end

  def fetch_inventory
    response = fetch_database_inventory
    online_trades_response = fetch_active_trades
    if online_trades_response['success'] == false
      report_api_error(online_trades_response, [self&.class&.name, __method__.to_s])
    else
      online_trades = JSON.parse(online_trades_response.read_body)
      api_item_ids = online_trades["data"]["deposits"].map { |deposit| deposit["item_id"] }
      filtered_response = response.reject { |item| api_item_ids.include?(item["id"]) }
    end
    filtered_response
  end

  private

  def fetch_database_inventory
    SellableInventory.inventory(@steam_account).where(listed_for_sale: false)
  end

  def fetch_active_trades
    headers = {
      'Authorization' => "Bearer #{@steam_account.market_csgo_api_key}",
    }

    HTTParty.get(MARKET_CSGO_BASE_URL + '/trades', query: @params)
  end
end
