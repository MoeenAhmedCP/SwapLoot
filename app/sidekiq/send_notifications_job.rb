class SendNotificationsJob
  include Sidekiq::Job
    
  def perform(user_id, item, notification_type)
    p "<=========== Notification sending ===================>"
    current_user = User.find(user_id)
    @notification = current_user.notifications.create(title: "Item #{notification_type}", body: "#{item["data"]["item"]["market_name"]} #{notification_type} with ID: (#{item["data"]["item_id"]}) at price (#{(item["data"]["total_value"].to_f)/100}) coins", notification_type: notification_type)
    ActionCable.server.broadcast("flash_messages_channel_#{current_user.id}", { message: "#{item["data"]["item"]["market_name"]} #{notification_type} with ID: (#{item["data"]["item_id"]}) at price (#{(item["data"]["total_value"].to_f)/100}) coins" })
    p "<=========== Discord Notification sending ===================>"
    notify_discord(current_user, @notification.body) if current_user.discord_bot_token.present? && current_user.discord_channel_id.present?
    if notification_type == "Sold"
      item_id = item['data']['item_id']
      remove_item_for_sale(current_user, item_id) if current_user.present? && item_id.present?
      inventory = Inventory.find_by(item_id: item_id)
      if inventory.present?
        inventory.soft_delete_and_set_sold_at
      end
      sellable_item = SellableInventory.find_by(item_id: item_id)
      sellable_item.destroy if sellable_item.present?
    else
      # Inventory.create(item_id: item[0]["data"]["item_id"], market_name: item[0]["data"]["item"]["market_name"] , market_price: (item[0]["data"]["item"]["market_value"] * 0.614) )
    end
  end

  def notify_discord(current_user, message)
    begin
      bot = Discordrb::Bot.new(token: current_user.discord_bot_token)
      channel = bot.channel(current_user.discord_channel_id)
      channel.send_message(message)
    rescue StandardError => e
      @notification = current_user.notifications.create(title: "Discord Login", body: "User is unauthorized", notification_type: "Login")
      ActionCable.server.broadcast("flash_messages_channel_#{current_user.id}", { message: "Unauthorized discord user" })
    end
  end

  def remove_item_for_sale(user, item_id)
    CsgoempireService.new(user).remove_item(item_id)
    WaxpeerService.new(user).remove_item(item_id)
  end
end
