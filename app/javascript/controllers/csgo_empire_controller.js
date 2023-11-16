import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="csgo"
export default class extends Controller {
  connect() {
    console.log("Connected to CSGO Empire controller")
    this.fetchCsGoEmpireData()
  }

  async fetchCsGoEmpireData() {
    const csgoempireApiKey = "";
    const socketEndpoint = "wss://trade.csgoempire.com/trade";
    // axios.defaults.headers.common['Authorization'] = `Bearer ${csgoempireApiKey}`;

    console.log("Connecting to websocket...");

    try {
      const userData = (await axios.get("https://csgoempire.com/api/v2/metadata/socket", {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${csgoempireApiKey}`,
          'Access-Control-Allow-Origin': '*',
        },
      })).data;

      console.log("userData", userData)

      // const userData = {
      //   user: {
      //     id: 8065093
      //   },
      //   socket_token: "seEQvWcTjIQUmuZYJJJuC7oYsfQ1fTJcDkWt1pKISrVF",
      //   socket_signature: "47cf69f2b29c35bbde5de0dffbc4aae130c4eb43aee8e361504baf8c1a8a61221fa513f20e6928e11810ec3caf8ff24bbf88e16088d9a18a3e0bc1538ba57a6e"
      // }

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
        socket.on('new_item', (data) => console.log(`new_item: ${JSON.stringify(data)}`));
        socket.on('updated_item', (data) => console.log(`updated_item: ${JSON.stringify(data)}`));
        socket.on('auction_update', (data) => console.log(`auction_update: ${JSON.stringify(data)}`));
        socket.on('deleted_item', (data) => console.log(`deleted_item: ${JSON.stringify(data)}`));
        socket.on('trade_status', (data) => console.log(`trade_status: ${JSON.stringify(data)}`));
        socket.on("disconnect", (reason) => console.log(`Socket disconnected: ${reason}`));
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
