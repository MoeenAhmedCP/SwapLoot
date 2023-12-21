import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import consumer from "../channels/consumer";

// Connects to data-controller="csgo"
export default class extends Controller {
  connect() {
    this.applyDarkModePreference();
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