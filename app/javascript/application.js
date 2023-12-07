// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "./channels"
import "chartkick/chart.js"


var elements = document.querySelectorAll('.dataTables_length');

// Loop through the selected elements and remove each one
for (var i = 0; i < elements.length; i++) {
  elements[i].parentNode.removeChild(elements[i]);
}