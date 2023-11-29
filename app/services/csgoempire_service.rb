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

  def fetch_active_trade
    return if csgoempire_key_not_found?

    self.class.get(CSGO_EMPIRE_BASE_URL + '/trading/user/trades', headers: @headers)
  end

  def remove_item(deposit_id)
    return if csgoempire_key_not_found?

    self.class.get("#{BASE_URL}/trading/deposit/#{deposit_id}/cancel", headers: @headers)
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
