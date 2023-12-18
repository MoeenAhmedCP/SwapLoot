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
      begin
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: @headers)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end

      if response['success'] == false
        report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
        return []
      else
        response_data = response['user'] ? response['user']['balance'].to_f / 100 : 0
      end
    else
      response_data = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          response = self.class.get(CSGO_EMPIRE_BASE_URL + '/metadata/socket', headers: headers(steam_account&.csgoempire_api_key))
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
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
    TradeStatusJob.perform_async(data)
  end

  def fetch_item_listed_for_sale
    response = []
    if @active_steam_account.present?
      return [] if csgoempire_key_not_found?
      begin
        res = self.class.get(BASE_URL + '/trading/user/trades', headers: @headers)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end
      if res['success'] == true
        response = res['data']['deposits']
      else
        report_api_error(res, [self&.class&.name, __method__.to_s])
        []
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          res = self.class.get(BASE_URL + '/trading/user/trades', headers: headers(steam_account.csgoempire_api_key))
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
        response += res['data']['deposits'] if res['success'] == true
      end
    end
    response
  end

  def self.fetch_user_data(steam_account)
    headers = { 'Authorization' => "Bearer #{steam_account&.csgoempire_api_key}" }
    begin
      response = self.get(BASE_URL + '/metadata/socket', headers: headers)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end
    if response['success'] == false
      report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
      return []
    else
      response
    end
  end

  def fetch_my_inventory
    if @active_steam_account.present?
      return if csgoempire_key_not_found?
      begin
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: @headers)
        save_inventory(response, @active_steam_account) if response['success'] == true
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/inventory', headers: headers(steam_account.csgoempire_api_key))
          save_inventory(response, steam_account) if response['success'] == true
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
      end
    end
  end

  def save_inventory(res, steam_account)
    res['data']&.each do |item|
      inventory = Inventory.find_by(item_id: item['id'])
      unless inventory.present?
        item_price = item['market_value'] < 0 ? 0 : ((item['market_value'].to_f / 100) * 0.614).round(2)
        Inventory.create(item_id: item['id'], steam_id: steam_account&.steam_id, market_name: item['market_name'], market_price: item_price, tradable: item['tradable'])
      end
    end
  end

  def fetch_active_trade
    if @active_steam_account.present?
      return if csgoempire_key_not_found?
      begin
        response = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: @headers)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end
      if response['success'] == false
        report_api_error(response&.keys&.at(1), [self&.class&.name, __method__.to_s])
        return []
      else
        response
      end
    else
      response = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          res = self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: headers(steam_account.csgoempire_api_key))
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
        response << res
      end
      if response.present?
        merged_response = {
          'success' => response.all? { |resp| resp['success'] },
          'data' => {
            'deposits' => response.map do |resp|
              data = resp['data']
              deposits = data['deposits'] if data
            end.flatten.compact,
            'withdrawals' => response.map do |resp|
              data = resp['data']
              deposits = data['withdrawals'] if data
            end.flatten.compact
          }
        }
        response = merged_response
      end
    end
    response
  end

  def remove_item(deposit_id)
    begin
      response = self.class.get("#{BASE_URL}/trading/deposit/#{deposit_id}/cancel", headers: @headers)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end

    if response['success'] == false
      return []
    else
      response
    end
  end

  def save_transaction(response, steam_account)
    if response['data']
      SaveTransactionWorker.perform_async(response, steam_account.id, @headers)
    end
  end

  def create_item(id, market_name, b_price, s_price, date, steam_account)
    item = SoldItem.find_by(item_id: id)
    SoldItem.create(item_id: id, item_name: market_name, bought_price: b_price, sold_price: s_price, date: date, steam_account: steam_account) unless item.present?
  end

  def fetch_deposit_transactions
    if @active_steam_account.present?
      return if csgoempire_key_not_found?
      begin
        response = self.class.get("#{BASE_URL}/user/transactions", headers: @headers)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
        return []
      end
      save_transaction(response, @active_steam_account)
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.csgoempire_api_key.blank?
        begin
          response = self.class.get("#{BASE_URL}/user/transactions", headers: headers(steam_account.csgoempire_api_key))
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          return []
        end
        save_transaction(response, steam_account)
      end
    end
  end

  def process_transactions
    begin
      response = self.class.get("#{BASE_URL}/user/transactions", headers: @headers)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end

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
    begin
      response_data = self.class.get("#{BASE_URL}/user/transactions?page=#{page_number}", headers: @headers)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end

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

  def csgoempire_key_not_found?
    @active_steam_account&.csgoempire_api_key.blank?
  end

end
