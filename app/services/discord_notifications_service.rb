# frozen_string_literal: true

class DiscordNotificationsService
  attr_reader :message

  def initialize(message)
    @message = message
  end

  def call
    DiscordNotificationsJob.perform_later(@message)
  end
end
