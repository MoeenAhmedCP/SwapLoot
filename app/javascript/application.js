// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"


$( document ).ready(function() {
    const userMenuButton = document.getElementById("user-menu-button");
    const userDropdown = document.getElementById("user-dropdown");
  
    userMenuButton.addEventListener("click", () => {
        userDropdown.classList.toggle("hidden");
    });
});