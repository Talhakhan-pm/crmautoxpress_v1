import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actions", "composer", "quickActions"]

  connect() {
    console.log('Callback card controller connected')
    this.handlePostCallActionsState()
  }

  // Handle post-call actions state based on data attribute after Turbo Stream updates
  handlePostCallActionsState() {
    if (this.hasQuickActionsTarget) {
      const showState = this.quickActionsTarget.dataset.showState
      console.log('Post-call actions show state:', showState)
      
      if (showState === 'true') {
        // Webhook wants to show dropdown (e.g., after hangup)
        this.quickActionsTarget.style.display = 'block'
        console.log('Showing post-call actions from webhook')
      } else if (showState === 'false') {
        // Webhook wants to hide dropdown
        this.quickActionsTarget.style.display = 'none'
        console.log('Hiding post-call actions from webhook')
      } else if (showState === 'preserve') {
        // Check if dropdown was already visible before this update
        const wasVisible = sessionStorage.getItem(`callback-${this.element.dataset.callbackId}-dropdown-visible`)
        if (wasVisible === 'true') {
          this.quickActionsTarget.style.display = 'block'
          console.log('Preserving visible post-call actions state')
        } else {
          this.quickActionsTarget.style.display = 'none'
          console.log('Preserving hidden post-call actions state')
        }
      }
    }
  }

  toggleComposer(event) {
    event.preventDefault()
    console.log('Toggle composer clicked')
    
    const composer = this.composerTarget
    const isHidden = composer.style.display === 'none' || 
                     getComputedStyle(composer).display === 'none'
    
    if (isHidden) {
      this.showComposer()
    } else {
      this.hideComposer()
    }
  }

  showComposer() {
    console.log('Showing composer')
    this.composerTarget.style.display = 'block'
    
    // Focus on the textarea
    const textarea = this.composerTarget.querySelector('textarea')
    if (textarea) {
      setTimeout(() => textarea.focus(), 100)
    }
  }

  hideComposer() {
    console.log('Hiding composer')
    this.composerTarget.style.display = 'none'
    
    // Clear the textarea
    const textarea = this.composerTarget.querySelector('textarea')
    if (textarea) {
      textarea.value = ''
    }
  }

  // Called after successful form submission
  handleSuccess(event) {
    console.log('Message sent successfully')
    this.hideComposer()
    
    // Show brief success feedback
    this.showSuccessFeedback()
    
    // Clear any form validation errors
    this.clearFormErrors()
  }
  
  clearFormErrors() {
    const textarea = this.composerTarget.querySelector('textarea')
    if (textarea) {
      textarea.classList.remove('error')
    }
  }

  showSuccessFeedback() {
    const messageBtn = this.element.querySelector('.cb-action-message')
    if (messageBtn) {
      const originalText = messageBtn.innerHTML
      messageBtn.innerHTML = '<i class="fas fa-check"></i> Sent'
      messageBtn.style.background = '#dcfce7'
      messageBtn.style.color = '#166534'
      
      setTimeout(() => {
        messageBtn.innerHTML = originalText
        messageBtn.style.background = ''
        messageBtn.style.color = ''
      }, 2000)
    }
  }

  // Make call and track it
  makeCall(event) {
    console.log('Making call and tracking')
    const callbackId = event.currentTarget.dataset.callbackId
    const phoneNumber = event.currentTarget.dataset.phone
    
    if (!callbackId || !phoneNumber) {
      console.warn('Missing callback ID or phone number for call tracking')
      return
    }

    console.log('Initiating Dialpad call via API')
    console.log('Phone number:', phoneNumber)
    
    // Show visual feedback immediately
    this.showCallFeedback(event.currentTarget)
    
    // Initiate call via Dialpad API (backend handles everything)
    fetch(`/callbacks/${callbackId}/track_call`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      console.log('Dialpad API response:', data)
      
      if (data.status === 'success') {
        this.showSuccessNotification('Call initiated successfully! Check your Dialpad app.')
        // Show quick updates and next action after successful call initiation
        this.showPostCallActions()
      } else {
        this.showErrorNotification(data.message || 'Failed to initiate call')
      }
    })
    .catch(error => {
      console.error('Failed to initiate call:', error)
      this.showErrorNotification('Network error while initiating call')
    })
  }

  // Make call from order card and track it
  makeOrderCall(event) {
    console.log('Making order call and tracking')
    const orderId = event.currentTarget.dataset.orderId
    const phoneNumber = event.currentTarget.dataset.phone
    
    if (!orderId || !phoneNumber) {
      console.warn('Missing order ID or phone number for call tracking')
      return
    }

    console.log('Initiating Dialpad call via API for order')
    console.log('Phone number:', phoneNumber)
    
    // Show visual feedback immediately
    this.showCallFeedback(event.currentTarget)
    
    // Initiate call via Dialpad API (backend handles everything)
    fetch(`/orders/${orderId}/track_call`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      console.log('Dialpad API response:', data)
      
      if (data.status === 'success') {
        this.showSuccessNotification('Call initiated successfully! Check your Dialpad app.')
        // Show quick updates and next action after successful call initiation
        this.showPostCallActions()
      } else {
        this.showErrorNotification(data.message || 'Failed to initiate call')
      }
    })
    .catch(error => {
      console.error('Failed to initiate call:', error)
      this.showErrorNotification('Network error while initiating call')
    })
  }

  showCallFeedback(callBtn) {
    const originalText = callBtn.innerHTML
    const originalStyle = {
      background: callBtn.style.background,
      color: callBtn.style.color
    }
    
    // Check if this is an order card call (has data-order-id) vs callback card call
    const isOrderCall = callBtn.hasAttribute('data-order-id')
    
    if (isOrderCall) {
      // Order card: Show only spinning icon, no text
      callBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'
    } else {
      // Callback card: Show existing "Initiating..." text
      callBtn.innerHTML = '<i class="fas fa-phone-alt"></i> Initiating...'
      callBtn.style.background = '#dbeafe'
      callBtn.style.color = '#1e40af'
    }
    
    // Reset after delay
    setTimeout(() => {
      callBtn.innerHTML = originalText
      callBtn.style.background = originalStyle.background
      callBtn.style.color = originalStyle.color
    }, 3000)
  }
  
  showSuccessNotification(message) {
    this.showNotification(message, 'success')
  }
  
  showErrorNotification(message) {
    this.showNotification(message, 'error')
  }
  
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.className = `notification notification-${type}`
    notification.innerHTML = `
      <div class="notification-content">
        <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
        <span>${message}</span>
      </div>
    `
    
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
      max-width: 300px;
    `
    
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
    }, 5000) // Show for 5 seconds for call notifications
  }

  // Show post-call actions after call initiation
  showPostCallActions() {
    console.log('Showing post-call actions')
    
    // Show quick actions with smooth animation and enhanced styling
    if (this.hasQuickActionsTarget) {
      const quickActions = this.quickActionsTarget
      const callbackId = this.element.dataset.callbackId
      
      // Store visibility state for preservation across Turbo Stream updates
      sessionStorage.setItem(`callback-${callbackId}-dropdown-visible`, 'true')
      
      quickActions.classList.add('post-call-highlight')
      quickActions.style.display = 'block'
      quickActions.style.opacity = '0'
      quickActions.style.transform = 'translateY(-10px)'
      
      setTimeout(() => {
        quickActions.style.transition = 'all 0.3s ease'
        quickActions.style.opacity = '1'
        quickActions.style.transform = 'translateY(0)'
      }, 100)
    }
    
    // The combined form is already shown with quickActions, no separate next action needed
  }

  // Hide post-call actions
  hidePostCallActions() {
    if (this.hasQuickActionsTarget) {
      const callbackId = this.element.dataset.callbackId
      
      // Clear visibility state
      sessionStorage.removeItem(`callback-${callbackId}-dropdown-visible`)
      
      this.quickActionsTarget.style.display = 'none'
      // Clear the form
      const form = this.quickActionsTarget.querySelector('form')
      if (form) {
        form.reset()
      }
    }
  }
}