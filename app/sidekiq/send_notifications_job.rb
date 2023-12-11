class SendNotificationsJob
  include Sidekiq::Job
    
  def perform(*current_user, item, notification_type)
    p "<=========== Notification sending ===================>"
    @notification = current_user.notifications.create(title: "Item #{@notification_type}", body: "#{item[0]["data"]["item"]["market_name"]} #{notification_type} with ID: (#{item[0]["data"]["item_id"]}) at price (#{(item[0]["data"]["total_value"].to_f)/100}) coins", notification_type: notification_type)
    p "<=========== Discord Notification sending ===================>"
    notify_discord(current_user, @notification.body) if current_user.discord_bot_token.present? && current_user.discord_channel_id.present?
    if notification_type == "Sold"
      RemoveItems.remove_item_from_all_services(user, service_hash) if user.present?
      inventory = Inventory.find_by(item_id: item[0]['data']['item_id'])
      if inventory.present?
        inventory.soft_delete_and_set_sold_at
      end
    else
      # Inventory.create(item_id: item[0]["data"]["item_id"], market_name: item[0]["data"]["item"]["market_name"] , market_price: (item[0]["data"]["item"]["market_value"] * 0.614) )
    end
  end

  def notify_discord(message)
    begin
      bot = Discordrb::Bot.new(token: current_user.discord_bot_token)
      channel = bot.channel(current_user.discord_channel_id)
      channel.send_message(message)
    rescue StandardError => e
      @notification = current_user.notifications.create(title: "Discord Login", body: "User is unauthorized", notification_type: "Login")
    end
  end
end