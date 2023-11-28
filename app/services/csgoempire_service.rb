class CsgoempireService < ApplicationService
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
    if response['success'] == false
      report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      response['user']['balance'].to_f / 100 if response['user']
    end
  end

  def socket_data(data)
    if data['event'] == 'new_item'
      # for now, pass dummy values i.e. max_percentage = 20, specific_price = 100
      CsgoEmpireBuyingInitiateJob.perform_later(@current_user, data['item_data'], 20, 100)
    elsif data['event'] == 'trade_status'
      service_hash = set_remove_item_hash data
      RemoveItems.remove_item_from_all_services(@current_user, service_hash)
    end
  end
  
  def fetch_item_listed_for_sale
    return [] if csgoempire_key_not_found?

    res = self.class.get(BASE_URL + '/trading/user/trades', headers: @headers)
    if res["success"] == true
      res["data"]["deposits"]
    else
      report_api_error(res&.keys&.at(1), [self&.class&.name, __method__.to_s])
      []
    end
  end

  def self.fetch_user_data(steam_account)
    headers = { 'Authorization' => "Bearer #{steam_account&.csgoempire_api_key}" }
    response self.class.get(BASE_URL + '/metadata/socket', headers: headers)

    if response['success'] == false
      report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      response
    end
  end

  def fetch_active_trade
    response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: @headers)

    if response['success'] == false
      report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      response
    end
  end

  def remove_item(deposit_id)
    response = self.class.get("#{BASE_URL}/trading/deposit/#{deposit_id}/cancel", headers: @headers)

    if response['success'] == false
      report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      response
    end
  end

  def csgoempire_key_not_found?
    @active_steam_account&.csgoempire_api_key.blank?
  end

  def set_remove_item_hash(data)
    service_hash = { 'CsgoempireService': '', 'WaxpeerService': '' }
    trade_service_info = data['item_data'].first
    if trade_service_info['type'] == 'deposit' && trade_service_info.dig('data', 'status_message') == 'Completed'
      service_hash['WaxpeerService'] = trade_service_info.dig('data', 'item_id')
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
