class CsgoempireService
  include HTTParty
  
  BASE_URL = CSGO_EMPIRE_BASE_URL 

  def initialize(current_user)
    @current_user = current_user
    @active_steam_account = User.active_steam_account(current_user)
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

  def fetch_user_data(steam_account)
    return if steam_account&.csgoempire_api_key.nil?

    headers = { 'Authorization' => "Bearer #{steam_account&.csgoempire_api_key}" }
    self.class.get(BASE_URL + '/metadata/socket', headers: headers)
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
    @active_steam_account.csgoempire_api_key.blank?
  end
end
