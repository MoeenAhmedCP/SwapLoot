import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import consumer from "../channels/consumer";

// Connects to data-controller="csgo"
export default class extends Controller {
  static targets = ["user"]

  connect() {
    this.applyDarkModePreference();
    const userId = this.userTarget.getAttribute("data-user-id");
    this.subscribechannel(userId);
  }

  subscribechannel(userId){
    if (userId){
      consumer.subscriptions.create({
        channel: "FlashMessagesChannel",
        user_id: userId
      }, {
        connected() {
          // Called when the subscription is ready for use on the server
        },
      
        disconnected() {
          // Called when the subscription has been terminated by the server
        },
      
        received(data) {
          // Called when there's incoming data on the websocket for this channel
          $('#toast-success').removeClass('hidden').find('.success_message').text(data.message);
          setTimeout(function() {
            $('#toast-success').addClass('hidden');
          }, 10000);
        }
      });
    }
  }

  applyDarkModePreference() {
    const darkModePreference = localStorage.getItem('darkMode');
    const body = document.body;
    if (darkModePreference === 'true') {
      body.classList.add('dark');
    } else {
      body.classList.remove('dark');
    }
  }

}