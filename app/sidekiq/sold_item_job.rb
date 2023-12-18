class SoldItemJob
  include Sidekiq::Job
  queue_as :sold_item

  def perform(steam_account_id, page_number, headers)
    p "<=========== Sold Item Job started, page number: #{page_number} ===================>"
    begin
      response_data = CsgoempireService.get("#{CSGO_EMPIRE_BASE_URL}/user/transactions?page=#{page_number}", headers: headers)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
      return []
    end
    if response_data['data'].present?
      response_data['data'].each do |transaction_data|
        if transaction_data['key'] == 'deposit_invoices' && transaction_data['data']['status_name'] == 'Complete'
          item_data = transaction_data['data']['metadata']['item']
          item_id = transaction_data['data']['metadata']['item_id']
          sold_price = (transaction_data['delta']).to_f / 100
          if item_data
            create_item(item_data['asset_id'], item_data['market_name'], sold_price, item_data['market_value'], item_data['updated_at'], steam_account_id)
          end
        end
      end
    end
  end

  def create_item(id, market_name, b_price, s_price, date, steam_account_id)
    item = SoldItemHistory.find_by(item_id: id)
    SoldItemHistory.create(item_id: id, item_name: market_name, bought_price: b_price, sold_price: s_price, date: date, steam_account_id: steam_account_id) unless item.present?
  end
end
