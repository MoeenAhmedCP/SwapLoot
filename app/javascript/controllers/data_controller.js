import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import consumer from "../channels/consumer";

// Connects to data-controller="csgo"
export default class extends Controller {
  connect() {
    this.startAllChannelsSubscriptions();
  }

  async startAllChannelsSubscriptions() {
    const steamAccounts = await this.fetchAllSteamAccounts();

    steamAccounts.forEach((account) => {
      this.subscribeEventsChannel(account);
    });
  }

  subscribeEventsChannel(accountData) {
    const accountId = accountData.account_id;
    const userData = accountData.user_data;

    consumer.subscriptions.create(
      { channel: "CsgosocketChannel", channel_id: accountId },
      {
        connected() {
          // Called when the subscription is ready for use on the server
          this.fetchCsGoEmpireData();
        },

        disconnected() {
          // Called when the subscription has been terminated by the server
          console.log("disconnected from channel");
        },

        received(data) {
          // Called when there's incoming data on the websocket for this channel
        },

        async fetchCsGoEmpireData() {
          const socketEndpoint = "wss://trade.csgoempire.com/trade";

          if (userData) {
            try {
              const socket = io(socketEndpoint, {
                transports: ["websocket"],
                path: "/s/",
                secure: true,
                rejectUnauthorized: false,
                reconnect: true,
                extraHeaders: { "User-agent": `${userData.user.id} API Bot` }, //this lets the server know that this is a bot
              });

              socket.on("connect", async () => {
                // Called when the subscription is ready for use on the server
                console.log(`Connected to websocket`);

                // Handle the Init event
                socket.on("init", (data) => {
                  if (data && data.authenticated) {
                    console.log(`Successfully authenticated as ${data.name}`);

                    // Emit the default filters to ensure we receive events
                    socket.emit("filters", {
                      price_max: 9999999,
                    });
                  } else {
                    // When the server asks for it, emit the data we got earlier to the socket to identify this client as the user
                    socket.emit("identify", {
                      uid: userData.user.id,
                      model: userData.user,
                      authorizationToken: userData.socket_token,
                      signature: userData.socket_signature,
                    });
                  }
                });

                // Listen for the following event to be emitted by the socket after we've identified the user
                socket.on("timesync", (data) =>
                  console.log(`Timesync: ${JSON.stringify(data)}`)
                );

                socket.on("new_item", (data) => {
                  if (this.checkServiceRunning()) {
                    this.perform("send_csgo_empire_event", {
                      item_data: data,
                      event: "new_item",
                    });
                  }
                });

                socket.on("updated_item", (data) => {
                  // this.perform("send_csgo_empire_event", { item_data: data, event:"updated_item" });
                });

                socket.on("auction_update", (data) => {
                  // this.perform("send_csgo_empire_event", { item_data: data, event:"auction_update" });
                });

                socket.on("deleted_item", (data) => {
                  // this.perform("send_csgo_empire_event", { item_data: data, event:"deleted_item" });
                });

                socket.on("trade_status", (data) => {
                  if (this.checkServiceRunning()) {
                    this.perform("send_csgo_empire_event", {
                      item_data: data,
                      event: "trade_status",
                    });
                  }
                });

                socket.on("disconnect", (reason) =>
                  console.log(`Socket disconnected: ${reason}`)
                );
              });

              // Listen for the following event to be emitted by the socket in error cases
              socket.on("close", (reason) =>
                console.log(`Socket closed: ${reason}`)
              );

              socket.on("error", (data) => console.log(`WS Error: ${data}`));

              socket.on("connect_error", (data) =>
                console.log(`Connect Error: ${data}`)
              );
            } catch (e) {
              console.log(`Error while initializing the Socket. Error: ${e}`);
            }
          } else {
            console.log("Some error occurred while getting data");
            return;
          }
        },

        checkServiceRunning() {
          const steamBuyingServices = document.querySelectorAll(
            ".steam-buying-services"
          );

          if (steamBuyingServices.length > 0) {
            for (const checkbox of steamBuyingServices) {
              if (checkbox.checked && checkbox.id == accountId) {
                return true;
              }
            }
          }
          return false;
        },
      }
    );
  }

  async fetchAllSteamAccounts() {
    try {
      return await $.ajax({
        url: "/home/fetch_all_steam_accounts",
        method: "GET",
        dataType: "json",
        success: (response) => {
          return response;
        },
        error: (xhr, status, error) => {
          return error;
        },
      });
    } catch (error) {
      console.error("Error while fetching user data:", error);
      return error;
    }
  }
}
