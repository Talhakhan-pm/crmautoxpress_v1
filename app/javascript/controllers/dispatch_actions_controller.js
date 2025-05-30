import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "modalBody"]
  static values = { 
    refundId: Number,
    dispatchId: Number,
    replacementId: Number
  }

  connect() {
    console.log("Dispatch actions controller connected")
  }

  // Return authorization actions
  async authorizeReturn(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const refundId = this.refundIdValue
    if (!refundId) {
      this.showError('No refund ID found')
      return
    }

    if (!confirm('Authorize return and refund for this order?')) {
      return
    }

    try {
      const response = await fetch(`/resolution/${refundId}/authorize_return_and_refund`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const result = await this.handleResponse(response)
      
      if (result.success) {
        this.showSuccess('Return authorized successfully!')
        this.refreshView()
      } else {
        this.showError(result.message || 'Failed to authorize return')
      }
    } catch (error) {
      console.error('Error authorizing return:', error)
      this.showError('Error authorizing return: ' + error.message)
    }
  }

  async authorizeReplacement(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const refundId = this.refundIdValue
    if (!refundId) {
      this.showError('No refund ID found')
      return
    }

    if (!confirm('Authorize return and create replacement order?')) {
      return
    }

    try {
      const response = await fetch(`/resolution/${refundId}/authorize_return_and_replacement`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const result = await this.handleResponse(response)
      
      if (result.success) {
        this.showSuccess('Return and replacement authorized successfully!')
        this.refreshView()
      } else {
        this.showError(result.message || 'Failed to authorize replacement')
      }
    } catch (error) {
      console.error('Error authorizing replacement:', error)
      this.showError('Error authorizing replacement: ' + error.message)
    }
  }

  // Return management actions
  async generateReturnLabel(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const refundId = this.refundIdValue
    if (!refundId) {
      this.showError('No refund ID found')
      return
    }

    try {
      const response = await fetch(`/resolution/${refundId}/generate_return_label`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const result = await this.handleResponse(response)
      
      if (result.success) {
        this.showSuccess('Return label generated successfully!')
        this.refreshView()
      } else {
        this.showError(result.message || 'Failed to generate return label')
      }
    } catch (error) {
      console.error('Error generating return label:', error)
      this.showError('Error generating return label: ' + error.message)
    }
  }

  trackReturn(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const trackingNumber = event.currentTarget.dataset.trackingNumber
    if (!trackingNumber) {
      this.showError('No tracking number available')
      return
    }
    
    // Open tracking in new tab - could be enhanced with carrier detection
    const trackingUrl = `https://www.fedex.com/apps/fedextrack/?tracknumbers=${trackingNumber}`
    window.open(trackingUrl, '_blank')
  }

  async markReturnReceived(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const refundId = this.refundIdValue
    if (!refundId) {
      this.showError('No refund ID found')
      return
    }

    const condition = prompt('Enter condition notes for received return (optional):')
    
    try {
      const response = await fetch(`/resolution/${refundId}/mark_return_received`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ condition_notes: condition })
      })

      const result = await this.handleResponse(response)
      
      if (result.success) {
        this.showSuccess('Return marked as received!')
        this.refreshView()
      } else {
        this.showError(result.message || 'Failed to mark return received')
      }
    } catch (error) {
      console.error('Error marking return received:', error)
      this.showError('Error marking return received: ' + error.message)
    }
  }

  showReturnDetails(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const refundId = this.refundIdValue
    if (!refundId) {
      this.showError('No refund ID found')
      return
    }

    // Check if modal exists
    if (this.hasModalTarget && this.hasModalBodyTarget) {
      this.loadReturnDetails(refundId)
    } else {
      // Fallback: open in new tab
      window.open(`/refunds/${refundId}`, '_blank')
    }
  }

  async loadReturnDetails(refundId) {
    try {
      const response = await fetch(`/refunds/${refundId}`, {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html'
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.modalBodyTarget.innerHTML = html
        this.modalTarget.classList.add('active')
        document.body.style.overflow = 'hidden'
      } else {
        this.showError('Failed to load return details')
      }
    } catch (error) {
      console.error('Error loading return details:', error)
      this.showError('Error loading return details')
    }
  }

  // Replacement management actions
  showReplacementDetails(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const replacementId = this.replacementIdValue || event.currentTarget.dataset.replacementId
    if (!replacementId) {
      this.showError('No replacement order ID found')
      return
    }
    
    // Navigate to replacement order details
    window.open(`/orders/${replacementId}`, '_blank')
  }

  async startReplacementProcessing(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const dispatchId = this.dispatchIdValue
    if (!dispatchId) {
      this.showError('No dispatch ID found')
      return
    }

    if (!confirm('Start processing replacement order? This will create a new order and cancel the current dispatch.')) {
      return
    }

    try {
      const response = await fetch(`/dispatches/${dispatchId}/create_replacement_order`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const result = await this.handleResponse(response)
      
      if (result.success) {
        this.showSuccess('Replacement order created successfully!')
        this.refreshView()
      } else {
        this.showError(result.message || 'Failed to create replacement order')
      }
    } catch (error) {
      console.error('Error creating replacement order:', error)
      this.showError('Error creating replacement order: ' + error.message)
    }
  }

  async shipReplacement(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const dispatchId = this.dispatchIdValue
    if (!dispatchId) {
      this.showError('No dispatch ID found')
      return
    }

    const trackingNumber = prompt('Enter tracking number for replacement shipment:')
    if (!trackingNumber) {
      return
    }

    try {
      const response = await fetch(`/dispatches/${dispatchId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ 
          dispatch: { 
            dispatch_status: 'shipped',
            tracking_number: trackingNumber,
            shipment_status: 'shipped'
          }
        })
      })

      if (response.ok) {
        this.showSuccess('Replacement marked as shipped!')
        this.refreshView()
      } else {
        this.showError('Failed to update shipment status')
      }
    } catch (error) {
      console.error('Error updating shipment:', error)
      this.showError('Error updating shipment: ' + error.message)
    }
  }

  trackReplacement(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const trackingNumber = event.currentTarget.dataset.trackingNumber
    if (!trackingNumber) {
      this.showError('No tracking number available')
      return
    }
    
    // Open tracking in new tab
    const trackingUrl = `https://www.fedex.com/apps/fedextrack/?tracknumbers=${trackingNumber}`
    window.open(trackingUrl, '_blank')
  }

  createReplacementDispatch(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const replacementId = this.replacementIdValue || event.currentTarget.dataset.replacementId
    if (!replacementId) {
      this.showError('No replacement order ID found')
      return
    }

    if (!confirm('Create dispatch for this replacement order?')) {
      return
    }

    // Navigate to dispatch creation with pre-populated order
    window.location.href = `/dispatches/new?order_id=${replacementId}`
  }

  // Modal management
  closeModal(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('active')
      document.body.style.overflow = ''
    }
  }

  // Utility methods
  async handleResponse(response) {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    const contentType = response.headers.get('content-type')
    if (contentType && contentType.includes('application/json')) {
      return await response.json()
    } else {
      return { success: true } // Assume success for non-JSON responses
    }
  }

  getCSRFToken() {
    const token = document.querySelector('[name="csrf-token"]')
    return token ? token.content : ''
  }

  refreshView() {
    // Use Turbo to refresh the current frame or page
    if (window.Turbo) {
      Turbo.visit(window.location.toString(), { frame: "main_content" })
    } else {
      window.location.reload()
    }
  }

  showSuccess(message) {
    this.showNotification(message, 'success')
  }

  showError(message) {
    this.showNotification(message, 'error')
  }

  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `notification notification-${type}`
    notification.innerHTML = `
      <div class="notification-content">
        <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
        <span>${message}</span>
      </div>
    `
    
    // Style the notification
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: ${type === 'success' ? '#10b981' : '#ef4444'};
      color: white;
      padding: 12px 16px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      z-index: 10000;
      display: flex;
      align-items: center;
      gap: 8px;
      font-weight: 500;
      transform: translateX(100%);
      transition: transform 0.3s ease;
    `
    
    // Add to page
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
    }, 100)
    
    // Remove after delay
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification)
        }
      }, 300)
    }, 4000)
  }
}