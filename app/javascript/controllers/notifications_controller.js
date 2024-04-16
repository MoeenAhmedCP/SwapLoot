import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notifications"
export default class extends Controller {
  connect() {
  }
  
  disconnect() {
    fetch('/mark_all_as_read', {
      method: 'PUT',
      headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': '<%= Rails.csrfToken() %>' // Include CSRF token if using Rails CSRF protection
      }
    });
  }
}
