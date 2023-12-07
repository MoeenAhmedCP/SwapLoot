class Users::SessionsController < Devise::SessionsController
  include Geocoder::Result

  def create
    super do |resource|
      if resource.persisted?
        location = get_user_location(request.remote_ip)
        flash[:notice] = "User logged in with #{resource.email} from #{location}, (IP Address: #{request.remote_ip})"
        @notification = Notification.create(title: "User Logged In", body: "User logged in with email: #{resource.email}, from #{location}, (IP Address: #{request.remote_ip})", notification_type: "Login" )
        notify_discord(@notification.body)
      end
    end
  end

  def destroy
    super
  end

  private

  def get_user_location(ip)
    result = Geocoder.search(ip).first
    return "#{result.city}, #{result.region}" if result.is_a?(Geocoder::Result::Base)
      "Unknown Location"
    rescue
      "Unknown Location"
  end

  def notify_discord(message)
    bot = Discordrb::Bot.new(token: DISCORD_TOKEN)
    channel = bot.channel(DISCORD_CHANNEL_ID)
    channel.send_message(message)
  end
end
