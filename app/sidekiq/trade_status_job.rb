class TradeStatusJob
  include Sidekiq::Job
  sidekiq_options retry: false
  
  def perform(data)
    type = data['data']['market_type']
    case type
    when "csgoempire"
      p "<============= CSGOEmpire Trade Status Job started... ================>"
      begin
        if data['data']['event'] == 'trade_status'
          steam_account = SteamAccount.find_by(id: data['data']['steam_id'])
          user = steam_account&.user
          data['data']['item_data'].each do |item|
            if item['type'] == 'deposit'
              if item['data']['status'] == 2
                ListedItem.create(item_id: item['data']['item_id'], item_name: item['data']['item']['market_name'], price: ((item['data']['total_value']).to_f/100).round(2).to_s, site: "CSGO Empire", steam_account_id: steam_account.id)
                ActionCable.server.broadcast("flash_messages_channel_#{user.id}", { message: 'Item listed for sale', item_id: item['data']['item_id'], steam_account_id: steam_account.id })
              end
              if item['data']['status'] == 8
                listed_item = ListedItem.find_by(item_id: item['data']['item_id'])
                listed_item.destroy if listed_item.present?
                ActionCable.server.broadcast("flash_messages_channel_#{user.id}", { message: 'Item listed for sale', item_id: item['item_id'], steam_account_id: steam_account.id })
              end
              if item['data']['status_message'] == 'Sent'
                SendNotificationsJob.perform_async(user.id, item, "Sold", steam_account.id, "csgoempire")
                begin
                  listed_item = ListedItem.find_by(item_id: item['data']['item_id'])
                  listed_item.destroy if listed_item.present?
                  ActionCable.server.broadcast("flash_messages_channel_#{user.id}", { message: 'Item listed for sale', item_id: item['data']['item_id'], steam_account_id: steam_account.id })
                  sold_price = (item['data']['total_value']).to_f / 100
                  create_item(item['data']['item_id'], item['data']['item']['market_name'], item['data']['item']['market_value'] * 0.614, sold_price, item['data']['created_at'], steam_account)
                rescue StandardError => e
                  ActionCable.server.broadcast("flash_messages_channel_#{user.id}", { message: "#{e.message}", item_id: item['data']['item_id'], steam_account_id: steam_account.id })
                end
              end
            end
            if item['data']['status_message'] == 'Completed' && item["type"] == "withdrawal"
              SendNotificationsJob.perform_async(user.id, item, "Bought", steam_account.id, "csgoempire")
            end
          end
        end
      rescue => e
      end
    when "waxpeer"
      p "<============= Waxpeer Trade Status Job started... ================>"
      begin
        if data['data']['event'] == "steamTrade" &&  data['data']['item_data']['type'] == "update"
          steam_account = SteamAccount.find_by(id: data['data']['steam_id'])
          user = steam_account&.user
          data['data']['item_data']['data']['items'].each do |item|
            if item['status'] == 5
              SendNotificationsJob.perform_async(user.id, item, "Sold", steam_account.id, "waxpeer")
              begin
                ActionCable.server.broadcast("flash_messages_channel_#{user.id}", { message: 'Item Sold Successfully', item_id: item['item_id'], steam_account_id: steam_account.id })
                inventory_item = SellableInventory.find_by(item_id: item['item_id'])
                bought_price = inventory_item.present? ? inventory_item.market_price.to_f : 0
                create_item(item['item_id'], item['name'], (bought_price / 100.to_f), (item['price'] / 1000.to_f), item['sent_time'], steam_account)
              rescue StandardError => e
                ActionCable.server.broadcast("flash_messages_channel_#{user.id}", { message: "#{e.message}", item_id: item['item_id'], steam_account_id: steam_account.id })
              end
            end
            # if item['data']['status_message'] == 'Completed' && item["type"] == "withdrawal"
            #   SendNotificationsJob.perform_async(user.id, item, "Bought", steam_account.id)
            # end
          end
        end
      rescue => e
      end
    end
  end

  def create_item(id, market_name, b_price, s_price, date, steam_account)
    item = SoldItem.find_by(item_id: id)
    SoldItem.create(item_id: id, item_name: market_name, bought_price: b_price, sold_price: s_price, date: date, steam_account: steam_account) unless item.present?
  end
end
