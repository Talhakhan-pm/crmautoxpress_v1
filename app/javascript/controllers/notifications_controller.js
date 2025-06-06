import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "bell", "badge", "list"]

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener('click', this.closeOnOutsideClick.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.closeOnOutsideClick.bind(this))
  }

  toggle(event) {
    event.stopPropagation()
    
    if (this.dropdownTarget.style.display === 'none') {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.dropdownTarget.style.display = 'block'
    this.bellTarget.classList.add('active')
  }

  hide() {
    this.dropdownTarget.style.display = 'none'
    this.bellTarget.classList.remove('active')
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  markAsRead(event) {
    const notificationItem = event.currentTarget
    const notificationId = notificationItem.dataset.notificationId
    
    // Make AJAX request to mark as read
    fetch(`/notifications/${notificationId}/mark_read`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    }).then(response => {
      if (response.ok) {
        // Remove unread styling
        notificationItem.classList.remove('unread')
        
        // Update badge count
        this.updateBadgeCount(-1)
        
        // Navigate to callback
        const callbackUrl = notificationItem.dataset.callbackUrl
        if (callbackUrl) {
          window.location.href = callbackUrl
        }
      }
    }).catch(error => {
      console.error('Error marking notification as read:', error)
    })
  }

  markAllRead() {
    fetch('/notifications/mark_all_read', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    }).then(response => {
      if (response.ok) {
        // Remove all unread styling
        this.element.querySelectorAll('.notification-item.unread').forEach(item => {
          item.classList.remove('unread')
        })
        
        // Hide badge
        if (this.hasBadgeTarget) {
          this.badgeTarget.style.display = 'none'
        }
      }
    }).catch(error => {
      console.error('Error marking all notifications as read:', error)
    })
  }

  updateBadgeCount(change) {
    if (!this.hasBadgeTarget) return
    
    const currentCount = parseInt(this.badgeTarget.textContent) || 0
    const newCount = Math.max(0, currentCount + change)
    
    if (newCount === 0) {
      this.badgeTarget.style.display = 'none'
    } else {
      this.badgeTarget.textContent = newCount
      this.badgeTarget.style.display = 'block'
    }
  }
}