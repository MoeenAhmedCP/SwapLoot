class MissingItemsService < ApplicationService
  include HTTParty
  BASE_URL = CSGO_EMPIRE_BASE_URL

  def initialize(user)
    @user = user
    @active_steam_account = @user.active_steam_account
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
    reset_proxy
    add_proxy if @active_steam_account&.proxy.present?
  end

  def headers(api_key, steam_account)
    reset_proxy
    add_proxy(steam_account) if steam_account&.proxy.present?
    @headers = { 'Authorization' => "Bearer #{api_key}" }
  end

  def missing_items
    response = []
    if @active_steam_account.present?
      url = CSGO_EMPIRE_BASE_URL + '/trading/user/inventory'
      response = self.class.get(url, headers: @headers)
      if response['success'] == false
        report_api_error(response, [self&.class&.name, __method__.to_s])
      else
        if response['data']
          api_inventory_item = response['data'].pluck('id')
          response = Inventory.where.not(item_id: api_inventory_item).where(steam_id: @active_steam_account.steam_id, sold_at: nil)
        end
      end
    else
      @user.steam_accounts.each do |steam_account|
        response_data = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers(steam_account&.csgoempire_api_key, steam_account))
        if response_data['success'] == false
          report_api_error(response_data, [self&.class&.name, __method__.to_s])
        else
          if response_data['data']
            api_inventory_item = response_data['data'].pluck('id')
            res = Inventory.where.not(item_id: api_inventory_item).where(steam_id: steam_account.steam_id, sold_at: nil)
            response << res if res.present?
          end
        end
      end
    end
    response
  end

  def add_proxy(steam_account)
    proxy = steam_account&.proxy
    self.class.http_proxy proxy.ip, proxy.port, proxy.username, proxy.password if proxy.present?
  end
end
