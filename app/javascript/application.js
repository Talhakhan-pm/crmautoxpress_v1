// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./callbacks"
import "./google_ads"

// Simple test to verify Turbo is loaded
console.log("Turbo loaded:", window.Turbo ? "yes" : "no")

// Navigation active state handling
document.addEventListener('DOMContentLoaded', function() {
  const navItems = document.querySelectorAll('.nav-item');
  
  navItems.forEach(item => {
    item.addEventListener('click', function(e) {
      // Only handle if it's a clickable nav item (not the callback link which has real href)
      if (this.getAttribute('href') === '#') {
        e.preventDefault();
        
        // Remove active class from all nav items
        navItems.forEach(nav => nav.classList.remove('active'));
        
        // Add active class to clicked item
        this.classList.add('active');
      }
    });
  });
});
