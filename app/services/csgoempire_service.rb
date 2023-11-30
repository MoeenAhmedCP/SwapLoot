class CsgoempireService < ApplicationService
  include HTTParty
  
  BASE_URL = CSGO_EMPIRE_BASE_URL 

  def initialize(current_user)
    @current_user = current_user
    @active_steam_account = current_user.active_steam_account
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end

  def headers(api_key)
    @headers = { 'Authorization' => "Bearer #{api_key}" }
  end

  def fetch_balance
    if @active_steam_account.present?
      return if csgoempire_key_not_found?

      response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: @headers)
      if response['success'] == false
        report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
      else
        response_data = response['user'] ? response['user']['balance'].to_f / 100 : 0
      end
    else
      response_data = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?

        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: headers(steam_account&.csgoempire_api_key))
        response = {
          account_id: steam_account.id,
          balance: response['user']['balance'].to_f / 100
        }
        response_data << response
      end
    end
    response_data
  end

  def socket_data(data)
    if data['event'] == 'new_item'
      # for now, pass dummy values i.e. max_percentage = 20, specific_price = 100
      CsgoEmpireBuyingInitiateJob.perform_later(@current_user, data['item_data'], 20, 100)
    end
  end
  
  def fetch_item_listed_for_sale
    response = []
    if @active_steam_account.present?
      return [] if csgoempire_key_not_found?
      res = self.class.get(BASE_URL + '/trading/user/trades', headers: @headers)
      if res['success'] == true
        response = res['data']['deposits']
      else
        report_api_error(res&.keys&.at(1), [self&.class&.name, __method__.to_s])
        []
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?

        res = self.class.get(BASE_URL + '/trading/user/trades', headers: headers(steam_account.csgoempire_api_key))
        response += res['data']['deposits'] if res['success'] == true
      end
    end
    response
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
    if @active_steam_account.present?
      return if csgoempire_key_not_found?

      response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: @headers)

      if response['success'] == false
        report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
      else
        response
      end
    else
      response = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?

        res = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers(steam_account.csgoempire_api_key))
        response << res
      end
      if response.present?
        merged_response = {
          'success' => response.all? { |resp| resp['success'] },
          'data' => {
            'deposits' => response.map { |resp| resp['data']['deposits'] }.flatten,
            'withdrawals' => response.map { |resp| resp['data']['withdrawals'] }.flatten
          }
        }
        response = merged_response
      end
    end
    response
  end

  def remove_item(deposit_id)
    response = self.class.get("#{BASE_URL}/trading/deposit/#{deposit_id}/cancel", headers: @headers)

    if response['success'] == false
      report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      response
    end
  end

  def fetch_deposit_transactions
    return if csgoempire_key_not_found?

    response = self.class.get("#{BASE_URL}/user/transactions", headers: @headers)
    if response['data']
      last_page = response['last_page'].to_i
      (1..last_page).each do |page_number|
        response_data = self.class.get("#{BASE_URL}/user/transactions?page=#{page_number}", headers: @headers)
        if response_data['data'].present?
          response_data['data'].each do |transaction_data|
            if transaction_data['key'] == 'deposit_invoices' && transaction_data['data']['status_name'] == 'Complete'
              item_data = transaction_data['data']['metadata']['item']
              if item_data
                inventory = Inventory.find_by(item_id: item_data['asset_id'])
                create_item(item_data['asset_id'], item_data['market_name'], inventory.market_price, item_data['market_value'], item_data['updated_at'])
              end
            end
          end
        end
      end
    end
  end

  def process_transactions
    response = self.class.get("#{BASE_URL}/user/transactions", headers: @headers)

    if response['data']
      last_page = response['last_page'].to_i
      threads = []

      (1..last_page).each do |page_number|
        threads << Thread.new { process_page(page_number) }
      end

      # Wait for all threads to complete
      threads.each(&:join)
    end
  end

  def process_page(page_number)
    response_data = self.class.get("#{BASE_URL}/user/transactions?page=#{page_number}", headers: @headers)

    return unless response_data['data'].present?

    response_data['data'].each do |transaction_data|
      process_transaction(transaction_data) if valid_transaction?(transaction_data)
    end
  end

  def valid_transaction?(transaction_data)
    transaction_data['key'] == 'deposit_invoices' &&
      transaction_data['data']['status_name'] == 'Complete' &&
      transaction_data['data']['metadata']['item'].present?
  end

  def process_transaction(transaction_data)
    item_data = transaction_data['data']['metadata']['item']
    inventory = Inventory.find_by(item_id: item_data['asset_id'])
    create_item(item_data['asset_id'], item_data['market_name'], inventory.market_price, item_data['market_value'], item_data['updated_at'])
  end

  def create_item(id, market_name, b_price, s_price, date)
    item = Item.find_by(item_id: id)
    Item.create(item_id: id, item_name: market_name, bought_price: b_price, sold_price: s_price, date: date, steam_account: @current_user.active_steam_account) unless item.present?
  end

  def csgoempire_key_not_found?
    @active_steam_account&.csgoempire_api_key.blank?
  end
end
