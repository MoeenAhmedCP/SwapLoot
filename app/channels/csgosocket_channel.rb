class CsgosocketChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "csgosocket_channel_#{params[:channel_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

  def send_csgo_empire_event(data)
    CsgoempireService.new(current_user).socket_data(data)
  end
end
