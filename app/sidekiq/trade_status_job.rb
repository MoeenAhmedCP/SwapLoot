class TradeStatusJob
  include Sidekiq::Job
  
  def perform(data)
    p "<============= Trade Status Job started... ================>"
    begin
      if data['data']['event'] == 'trade_status'
        steam_account = SteamAccount.find_by(id: data['data']['steam_id'])
        user = steam_account&.user
        data['data']['item_data'].each do |item|
          if item['data']['status_message'] == 'Sent' && item["type"] == "deposit"
            SendNotificationsJob.perform_async(user, item, "Sold")
            begin
              sold_price = (item['total_value']).to_f / 100
              create_item(item['data']['item_id'], item['data']['item']['market_name'], sold_price, item['data']['market_value'] * 0.614, item['data']['created_at'], steam_account)
            rescue StandardError => e
            end
          end
          if item['data']['status_message'] == 'Completed' && item["type"] == "withdrawal"
            SendNotificationsJob.perform_async(user, item, "Bought")
          end
        end
      end
    rescue => e
    end
  end

  def create_item(id, market_name, b_price, s_price, date, steam_account)
    item = SoldItem.find_by(item_id: id)
    SoldItem.create(item_id: id, item_name: market_name, bought_price: b_price, sold_price: s_price, date: date, steam_account: steam_account) unless item.present?
  end
end