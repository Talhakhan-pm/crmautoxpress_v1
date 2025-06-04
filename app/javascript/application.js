// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@rails/actioncable"
import "controllers"
import "./google_ads"

// Simple test to verify Turbo is loaded
console.log("Turbo loaded:", window.Turbo ? "yes" : "no")
console.log("Stimulus loaded:", window.Stimulus ? "yes" : "no")

// Debug Stimulus controllers
document.addEventListener('DOMContentLoaded', () => {
  setTimeout(() => {
    if (window.Stimulus && window.Stimulus.application) {
      console.log("Stimulus app loaded successfully")
    }
  }, 1000)
})

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

// === DISPATCH FUNCTIONALITY ===
// Removed legacy global functions - now handled by Stimulus controllers:
// - dispatch-filter-controller handles search and filtering
// - dispatch-navigation-controller handles card clicks and navigation

// === GLOBAL RESOLUTION HUB FUNCTIONALITY ===
// Available on all pages for seamless resolution workflow

window.openResolutionHub = function(refundId, stage) {
  console.log('Opening hub for refund:', refundId, 'stage:', stage);
  
  // For now, navigate to resolution center with the specific refund
  // This provides a working solution while we build the modal
  const url = `/resolution#refund_${refundId}`;
  
  if (window.Turbo) {
    Turbo.visit(url, { frame: "main_content" });
  } else {
    window.location.href = url;
  }
};

// Global function to restore page scrolling (useful for modal cleanup)
window.restorePageScrolling = function() {
  console.log('Restoring page scrolling globally');
  
  // Remove all possible modal-related classes and styles
  document.body.classList.remove('modal-open', 'no-scroll');
  document.body.style.overflow = '';
  document.body.style.overflowY = '';
  document.body.style.paddingRight = '';
  document.body.style.position = '';
  document.body.style.top = '';
  document.body.style.width = '';
  document.body.style.height = '';
  
  // Also restore on html element
  document.documentElement.style.overflow = '';
  document.documentElement.style.overflowY = '';
  
  console.log('Page scrolling fully restored');
};

// Turbo navigation event listeners for cleanup
document.addEventListener('turbo:before-visit', function(event) {
  console.log('Turbo navigation starting - cleaning up');
  
  // Restore any stuck scrolling states
  if (window.restorePageScrolling) {
    window.restorePageScrolling();
  }
  
  // Clean up any stuck modal states
  document.querySelectorAll('.modal-open, .unified-modal.active').forEach(element => {
    element.classList.remove('modal-open', 'active');
  });
});

document.addEventListener('turbo:load', function(event) {
  console.log('Turbo page loaded successfully');
});
