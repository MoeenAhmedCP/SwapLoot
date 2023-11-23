class WaxPeerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "waxpeer_live_data_channel"

    get_waxpeer_live_events
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def get_waxpeer_live_events
    EM.run do
      ws = Faye::WebSocket::Client.new('wss://wssex.waxpeer.com')

      ws.on :open do |event|
        puts "Connected to waxpeer socket"

        # Schedule a recurring task to send a message every 25 seconds to keep the connection live
        EM.add_periodic_timer(25) do
          puts "Sending ping message"
          ws.send("ping")
          puts "Ping message sent"
        end
      end
    
      ws.on :message do |event|
        p [:message, event.data]
      end
    
      ws.on :close do |event|
        puts "Disconnected to waxpeer socket"
      end
    end
  end
end
