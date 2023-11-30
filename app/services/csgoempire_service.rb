class CsgoempireService
  include HTTParty
  
  BASE_URL = CSGO_EMPIRE_BASE_URL 

  def initialize(current_user)
    @current_user = current_user
    @active_steam_account = current_user.active_steam_account
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end

  def fetch_balance
    return if csgoempire_key_not_found?

    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: @headers)
    response['user']['balance'].to_f / 100 if response['user']
  end

  def socket_data(data)
    if data['event'] == 'new_item'
      # for now, pass dummy values i.e. max_percentage = 20, specific_price = 100
      CsgoEmpireBuyingInitiateJob.perform_later(@current_user, data['item_data'], 20, 100)
    end
    if data['event'] == 'trade_status'
      data['item_data'].each do |item|
        if item['data']['status_message'] == 'Sent'
          inventory = Inventory.find_by(item_id: item['data']['item_id'])
          if inventory.present?
            inventory.soft_delete_and_set_sold_at
            # service_hash = set_remove_item_hash data
            # RemoveItems.remove_item_from_all_services(@current_user, service_hash)
          end
        end
      end
    end
  end

  def fetch_item_listed_for_sale
    return [] if csgoempire_key_not_found?

    res = self.class.get(BASE_URL + '/trading/user/trades', headers: @headers)
    if res["success"] == true
      res["data"]["deposits"]
    else
      []
    end
  end

  def self.fetch_user_data(steam_account)
    headers = { 'Authorization' => "Bearer #{steam_account&.csgoempire_api_key}" }
    HTTParty.get(BASE_URL + '/metadata/socket', headers: headers)
  end

  def fetch_my_inventory
    return if csgoempire_key_not_found?

    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: @headers)
    save_inventory(response)
  end

  def save_inventory(res)
    if @active_steam_account
      res['data']&.each do |item|
        inventory = Inventory.find_by(item_id: item['id'])
        unless inventory.present?
          Inventory.create(item_id: item['id'], steam_id: @active_steam_account&.steam_id, market_name: item['market_name'], market_price: ((item['market_value'] / 100) * 0.164), tradable: item['tradable'])
        end
      end
    end
  end

  def fetch_active_trade
    return if csgoempire_key_not_found?

    self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: @headers)
  end

  def remove_item(deposit_id)
    return if csgoempire_key_not_found?

    self.class.get("#{BASE_URL}/trading/deposit/#{deposit_id}/cancel", headers: @headers)
  end

  def csgoempire_key_not_found?
    @active_steam_account&.csgoempire_api_key.blank?
  end

  def set_remove_item_hash(data)
    service_hash = { 'CsgoempireService': '', 'WaxpeerService': '' }
    trade_service_info = data['item_data'].first
    if trade_service_info['type'] == 'deposit' && trade_service_info.dig('data', 'status_message') == 'Sent'
      service_hash['WaxpeerService'] = trade_service_info.dig('data', 'item', 'asset_id')
    end

    csgo_desposit_data = fetch_item_listed_for_sale
    csgo_desposit_data.each do |record|
      record['items'].each do |item_data|
        if item_data['id'] == trade_service_info.dig('data', 'item_id')
          service_hash['CsgoempireService'] = record['id']
          break
        end
      end
    end

    service_hash
  end
end
