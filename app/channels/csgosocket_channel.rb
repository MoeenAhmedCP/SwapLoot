class CsgosocketChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'csgosocket_channel'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_csgo_empire_event(data)
    CsgoempireService.new(current_user).socket_data(data)
  end
end
