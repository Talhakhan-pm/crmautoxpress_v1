import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actions", "composer"]

  connect() {
    console.log('Callback card controller connected')
    this.setupCallStatusSubscription()
  }

  setupCallStatusSubscription() {
    // Subscribe to call status updates for all agents via callback_dashboard channel
    if (window.callStatusSubscription) {
      return // Already subscribed
    }

    const updateUserElements = (data) => {
      // Find all status indicators for this specific user
      const indicators = document.querySelectorAll(`[data-user-id="${data.user_id}"].cb-call-status-indicator`)
      const statusTexts = document.querySelectorAll(`[data-user-id="${data.user_id}"].cb-call-status-text`)
      
      // Update each indicator and status text based on whether this card matches the target
      indicators.forEach(indicator => {
        const callbackId = indicator.dataset.callbackId
        const orderId = indicator.dataset.orderId
        const isTargetCard = (data.current_target_type === 'callback' && data.current_target_id == callbackId) ||
                            (data.current_target_type === 'order' && data.current_target_id == orderId)
        
        // Update data attributes
        indicator.dataset.callStatus = data.call_status
        indicator.dataset.targetType = data.current_target_type
        indicator.dataset.targetId = data.current_target_id
        
        // Update icon based on whether this card is the target
        const icon = indicator.querySelector('.cb-status-icon')
        if (icon) {
          if (isTargetCard && (data.call_status === 'calling' || data.call_status === 'on_call')) {
            icon.className = `fas fa-circle cb-status-icon cb-status-${data.call_status}`
          } else {
            icon.className = `fas fa-circle cb-status-icon cb-status-idle`
          }
        }
      })
      
      // Update status text elements
      statusTexts.forEach(statusText => {
        const callbackId = statusText.dataset.callbackId
        const orderId = statusText.dataset.orderId
        const isTargetCard = (data.current_target_type === 'callback' && data.current_target_id == callbackId) ||
                            (data.current_target_type === 'order' && data.current_target_id == orderId)
        
        // Update data attributes
        statusText.dataset.callStatus = data.call_status
        statusText.dataset.targetType = data.current_target_type
        statusText.dataset.targetId = data.current_target_id
        
        // Remove existing status classes
        statusText.classList.remove('status-idle', 'status-calling-target', 'status-on-call-target')
        
        // Update text and classes based on whether this card is the target
        if (isTargetCard && data.call_status === 'calling') {
          statusText.textContent = 'Calling this customer'
          statusText.classList.add('status-calling-target')
        } else if (isTargetCard && data.call_status === 'on_call') {
          statusText.textContent = 'On call with this customer'
          statusText.classList.add('status-on-call-target')
        } else {
          statusText.textContent = 'Idle'
          statusText.classList.add('status-idle')
        }
      })
    }

    const updateTargetCard = (data) => {
      console.log('🎯 Updating target card for:', data.current_target_type, data.current_target_id)
      
      // Handle both call start and call end scenarios
      if (data.current_target_type && data.current_target_id) {
        // CALL START: Show the caller on the target card
        updateCardForCaller(data)
      } else if (data.call_status === 'idle') {
        // CALL END: Need to refresh the page or revert cards
        console.log('🔄 Call ended - should refresh cards to show original creators')
        // For now, let's just trigger a page refresh for the affected cards
        // In production, you might want to store original user info and revert
        setTimeout(() => {
          if (window.Turbo) {
            window.location.reload()
          }
        }, 1000)
      }
    }

    const updateCardForCaller = (data) => {
      let targetCard
      if (data.current_target_type === 'callback') {
        targetCard = document.querySelector(`[data-callback-id="${data.current_target_id}"].cb-agent-avatar, [data-callback-id="${data.current_target_id}"].cb-call-status-indicator`)
      } else if (data.current_target_type === 'order') {
        targetCard = document.querySelector(`[data-order-id="${data.current_target_id}"].order-agent-avatar, [data-order-id="${data.current_target_id}"].cb-call-status-indicator`)
      }
      
      console.log('🔍 Found target card:', targetCard)
      
      if (targetCard) {
        // Find the parent container with agent info
        const agentContainer = targetCard.closest('.cb-agent-info') || targetCard.closest('.order-agent-status')
        console.log('📦 Agent container:', agentContainer)
        
        if (agentContainer) {
          const avatar = agentContainer.querySelector('.cb-agent-avatar, .order-agent-avatar')
          const agentName = agentContainer.querySelector('.cb-agent-name')
          const statusText = agentContainer.querySelector('.cb-call-status-text')
          
          console.log('🎭 Elements found - Avatar:', !!avatar, 'Name:', !!agentName, 'Status:', !!statusText)
          
          if (avatar && agentName && statusText) {
            // Get user's first letter from email
            const userEmail = data.user_email || 'Unknown'
            const firstLetter = userEmail.charAt(0).toUpperCase()
            const userName = userEmail.split('@')[0].replace(/[._]/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
            
            console.log('👤 Updating to show:', firstLetter, userName)
            
            // Update avatar letter (find the text node in avatar)
            const avatarTextNode = Array.from(avatar.childNodes).find(node => node.nodeType === Node.TEXT_NODE)
            if (avatarTextNode) {
              avatarTextNode.textContent = firstLetter
            } else {
              // If no text node, create one
              avatar.insertBefore(document.createTextNode(firstLetter), avatar.firstChild)
            }
            
            // Update agent name
            agentName.textContent = userName
            
            // Update status text
            if (data.call_status === 'calling') {
              statusText.textContent = 'Calling this customer'
              statusText.className = 'cb-call-status-text status-calling-target'
            } else if (data.call_status === 'on_call') {
              statusText.textContent = 'On call with this customer'
              statusText.className = 'cb-call-status-text status-on-call-target'
            }
            
            // Update all data attributes
            const indicator = avatar.querySelector('.cb-call-status-indicator')
            if (indicator) {
              indicator.dataset.userId = data.user_id
              indicator.dataset.callStatus = data.call_status
              indicator.dataset.targetType = data.current_target_type
              indicator.dataset.targetId = data.current_target_id
              
              // Update status icon
              const icon = indicator.querySelector('.cb-status-icon')
              if (icon) {
                icon.className = `fas fa-circle cb-status-icon cb-status-${data.call_status}`
              }
            }
            
            if (statusText) {
              statusText.dataset.userId = data.user_id
              statusText.dataset.callStatus = data.call_status
              statusText.dataset.targetType = data.current_target_type
              statusText.dataset.targetId = data.current_target_id
            }
            
            console.log('✅ Updated target card successfully')
          }
        }
      } else {
        console.log('❌ Target card not found for:', data.current_target_type, data.current_target_id)
      }
    }

    const updateAgentCallStatus = (data) => {
      console.log('Updating agent call status for user:', data.user_id, 'to:', data.call_status)
      console.log('Target:', data.current_target_type, data.current_target_id)
      
      // Handle both old user's elements and the target card elements
      updateUserElements(data)
      updateTargetCard(data)
    }

    // Create ActionCable subscription to callback_dashboard channel
    if (typeof window.consumer === 'undefined') {
      console.error('ActionCable consumer not available')
      return
    }
    
    window.callStatusSubscription = window.consumer.subscriptions.create("CallbackDashboardChannel", {
      connected() {
        console.log('✅ Connected to callback dashboard call status updates')
      },

      disconnected() {
        console.log('❌ Disconnected from callback dashboard call status updates')
      },

      received(data) {
        console.log('📡 Received callback dashboard update:', data)
        if (data.type === 'call_status_update') {
          updateAgentCallStatus(data)
        }
      }
    })
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
}