class MissingItemsService < ApplicationService
  include HTTParty
  BASE_URL = CSGO_EMPIRE_BASE_URL

  def initialize(user)
    @user = user
    @active_steam_account = @user.active_steam_account
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
    reset_proxy
    add_proxy(@active_steam_account) if @active_steam_account&.proxy.present?
  end

  def headers(api_key, steam_account)
    reset_proxy
    add_proxy(steam_account) if steam_account&.proxy.present?
    @headers = { 'Authorization' => "Bearer #{api_key}" }
  end

  def missing_items(response)
    if @active_steam_account.present?
      if response['success'] == false
        report_api_error(response, [self&.class&.name, __method__.to_s])
        return []
      else
        if response['data']
          api_inventory_item = response['data'].pluck('id')
          response = Inventory.where.not(item_id: api_inventory_item).where(steam_id: @active_steam_account.steam_id, sold_at: nil)
          save_missing_items(response, @active_steam_account)
        end
      end
    else
      @user.steam_accounts.each do |steam_account|
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers(steam_account&.csgoempire_api_key, steam_account))
        if response['success'] == false
          report_api_error(response, [self&.class&.name, __method__.to_s])
          return []
        else
          if response['data']
            api_inventory_item = response['data'].pluck('id')
            res = Inventory.where.not(item_id: api_inventory_item).where(steam_id: steam_account.steam_id, sold_at: nil)
            save_missing_items(response, steam_account)
            response << res if res.present?
          end
        end
      end
      response = response.flatten
    end
    response
  end

  def save_missing_items(response, steam_account)
    items_to_insert = []
    response.each do |item|
      inventory = MissingItem.find_by(item_id: item.item_id)
      unless inventory.present?
        items_to_insert << {
          item_id: item.item_id,
          steam_account_id: steam_account&.id,
          market_name: item.market_name,
          market_value: item.market_price
        }
      end
    end
    MissingItem.insert_all(items_to_insert) unless items_to_insert.empty?
  end

  def add_proxy(steam_account)
    proxy = steam_account&.proxy
    self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password if proxy.present?
  end
end
