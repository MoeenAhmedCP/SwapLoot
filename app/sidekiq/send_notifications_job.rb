class SendNotificationsJob
  include Sidekiq::Job
    
  def perform(*item, notification_type, user, service_hash)
    p "<=========== Notification sending ===================>"
    @notification = Notification.create(title: "Item #{@notification_type}", body: "#{item[0]["data"]["item"]["market_name"]} #{notification_type} with ID: (#{item[0]["data"]["item_id"]}) at price (#{(item[0]["data"]["total_value"].to_f)/100}) coins", notification_type: notification_type)
    p "<=========== Discord Notification sending ===================>"
    notify_discord(@notification.body)
    if notification_type == "Sold"
      RemoveItems.remove_item_from_all_services(user, service_hash) if user.present?
      inventory = Inventory.find_by(item_id: item[0]['data']['item_id'])
      if inventory.present?
        inventory.soft_delete_and_set_sold_at
      end
    else
      Inventory.create(item_id: item[0]["data"]["item_id"], market_name: item[0]["data"]["item"]["market_name"] , market_price: (item[0]["data"]["item"]["market_value"] * 0.614) )
    end
  end


  def notify_discord(message)
    bot = Discordrb::Bot.new(token: DISCORD_TOKEN)
    channel = bot.channel(DISCORD_CHANNEL_ID)
    channel.send_message(message)
  end
end