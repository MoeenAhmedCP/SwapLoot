class CsgosocketChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from 'csgosocket_channel'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def get_user_data(data)
    CsgoempireService.new(current_user).socket_data(data)
  end
end
