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

// === GLOBAL DISPATCH MODAL FUNCTIONS ===
// These need to be available everywhere
if (typeof window.openCancelModal === 'undefined') {
  window.openCancelModal = function(dispatchId) {
    document.getElementById('dispatch-id').value = dispatchId;
    const modal = new bootstrap.Modal(document.getElementById('cancel-dispatch-modal'));
    modal.show();
  };

  window.submitCancellation = function() {
    const form = document.getElementById('cancel-dispatch-form');
    const formData = new FormData(form);
    const dispatchId = formData.get('dispatch_id');
    const reason = formData.get('cancellation_reason');
    
    if (!reason) {
      alert('Please select a cancellation reason');
      return;
    }
    
    fetch(`/dispatches/${dispatchId}/cancel_with_refund`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Accept': 'application/json'
      },
      body: JSON.stringify({ cancellation_reason: reason })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        const modal = bootstrap.Modal.getInstance(document.getElementById('cancel-dispatch-modal'));
        modal.hide();
        
        // Show success toast
        showToast('success', data.message);
        
        // Reload page to show updates
        setTimeout(() => {
          window.location.reload();
        }, 1500);
      } else {
        alert('Error: ' + (data.errors ? data.errors.join(', ') : 'Unknown error'));
      }
    })
    .catch(error => {
      console.error('Error cancelling dispatch:', error);
      alert('Network error occurred');
    });
  };

  window.showToast = function(type, message) {
    const toast = document.createElement('div');
    toast.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
    toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
    toast.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast);
      }
    }, 5000);
  };
}

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
