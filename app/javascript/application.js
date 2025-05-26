// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@rails/actioncable"
import "controllers"
import "./callbacks"
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
// Only load if we're on dispatches page
if (window.location.pathname.includes('/dispatches')) {
  console.log('Loading dispatch functions');
  
  // Namespace protection to prevent redefinition
  if (typeof window.setView === 'undefined') {
    window.setView = function(view) {
      const url = new URL(window.location);
      if (view === 'list') {
        url.searchParams.set('view', 'list');
      } else {
        url.searchParams.delete('view');
      }
      
      Turbo.visit(url.toString(), { frame: "main_content" });
    };

    window.setFilter = function(type, value) {
      const url = new URL(window.location);
      if (value) {
        url.searchParams.set(type, value);
      } else {
        url.searchParams.delete(type);
      }
      
      Turbo.visit(url.toString(), { frame: "main_content" });
    };

    window.searchDispatches = function(query) {
      clearTimeout(window.searchTimeout);
      window.searchTimeout = setTimeout(() => {
        const url = new URL(window.location);
        if (query.trim()) {
          url.searchParams.set('search', query);
        } else {
          url.searchParams.delete('search');
        }
        
        Turbo.visit(url.toString(), { frame: "main_content" });
      }, 500);
    };

    window.showDispatchDetails = function(dispatchId) {
      const modal = document.getElementById('dispatch-modal');
      if (!modal) return;
      
      fetch(`/dispatches/${dispatchId}`, {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html'
        }
      })
      .then(response => response.text())
      .then(html => {
        document.getElementById('modal-body').innerHTML = html;
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
      })
      .catch(error => {
        console.error('Error loading dispatch details:', error);
      });
    };
    
    console.log('Dispatch functions loaded');
  }
}
