# frozen_string_literal: true

class DiscordNotificationsJob < ApplicationJob
  queue_as :discord_notifications

  def perform(message)
    bot = Discordrb::Bot.new(token: ENV['DISCORD_BOT_TOKEN'])
    channel = bot.channel(ENV['DISCORD_CHANNEL_ID'])
    channel.send_message(message)
  end
end
