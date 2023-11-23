import { Controller } from "@hotwired/stimulus"
import $ from "jquery";

import consumer from "../channels/consumer"
// Connects to data-controller="csgo"
export default class extends Controller {
  connect() {
     this.fetchCsGoEmpireData()
  }

  async fetch_user_data() {
    let userData = null;

    try {
      const data = await $.ajax({
        url: "/home/fetch_user_data",
        method: "GET",
        dataType: "json",
        success: (response) => {
          userData = {
            user: {
              id: response.user.id,
            },
            socket_token: response.socket_token,
            socket_signature: response.socket_signature,
          };
        },
        error: (xhr, status, error) => {
          console.error("Error:", error);
        },
      });

      return userData;
    } catch (error) {
      console.error("Error while fetching user data:", error);
    }
  }

  async fetchCsGoEmpireData() {
    const socketEndpoint = "wss://trade.csgoempire.com/trade";

    console.log("Connecting to websocket...");

    try {

      const userData = await this.fetch_user_data();

      const socket = io(
        socketEndpoint,
        {
            transports: ["websocket"],
            path: "/s/",
            secure: true,
            rejectUnauthorized: false,
            reconnect: true,
            extraHeaders: { 'User-agent': `${userData.user.id} API Bot` } //this lets the server know that this is a bot
        }
      );

      socket.on('connect', async () => {

        consumer.subscriptions.create({ channel: "CsgosocketChannel" }, {
          connected() {
            // Called when the subscription is ready for use on the server
            console.log(`Connected to websocket`);

            // Handle the Init event
            socket.on('init', (data) => {
                if (data && data.authenticated) {
                    console.log(`Successfully authenticated as ${data.name}`);
                    
                    // Emit the default filters to ensure we receive events
                    socket.emit('filters', {
                        price_max: 9999999
                    });
                    
                } else {
                    // When the server asks for it, emit the data we got earlier to the socket to identify this client as the user
                    socket.emit('identify', {
                        uid: userData.user.id,
                        model: userData.user,
                        authorizationToken: userData.socket_token,
                        signature: userData.socket_signature
                    });
                }
            })

            // Listen for the following event to be emitted by the socket after we've identified the user
            socket.on('timesync', (data) => console.log(`Timesync: ${JSON.stringify(data)}`));
            socket.on('new_item', (data) => {
              this.perform("send_csgo_empire_event", { item_data: data, event:"new_item" });
            });
            socket.on('updated_item', (data) => {
              this.perform("send_csgo_empire_event", { item_data: data, event:"updated_item" });
            });
            socket.on('auction_update', (data) => {
              this.perform("send_csgo_empire_event", { item_data: data, event:"auction_update" });
            });
            socket.on('deleted_item', (data) => {
              this.perform("send_csgo_empire_event", { item_data: data, event:"deleted_item" });
            });
            socket.on('trade_status', (data) => {
              this.perform("send_csgo_empire_event", { item_data: data, event:"trade_status" });
            });
            socket.on("disconnect", (reason) => console.log(`Socket disconnected: ${reason}`));
          },
    
          disconnected() {
            // Called when the subscription has been terminated by the server
          },
    
          received(data) {
            // Called when there's incoming data on the websocket for this channel
          }
        });
      });

      // Listen for the following event to be emitted by the socket in error cases
      socket.on("close", (reason) => console.log(`Socket closed: ${reason}`));
      socket.on('error', (data) => console.log(`WS Error: ${data}`));
      socket.on('connect_error', (data) => console.log(`Connect Error: ${data}`));
    } catch (e) {
      console.log(`Error while initializing the Socket. Error: ${e}`);
    }
  }
}
