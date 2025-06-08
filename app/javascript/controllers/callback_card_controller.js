import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actions", "composer"]

  connect() {
    console.log('Callback card controller connected')
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

    // Clean phone number for callto: protocol (remove spaces, keep only digits)
    const cleanPhone = phoneNumber.replace(/\D/g, '') // Remove all non-digits
    const calltoUrl = `callto:${cleanPhone}` // Use the format that works
    
    console.log('Original phone:', phoneNumber)
    console.log('Cleaned phone:', cleanPhone)
    console.log('Triggering call with:', calltoUrl)
    
    // CRITICAL: Trigger call IMMEDIATELY while user gesture is active
    window.location.href = calltoUrl
    
    // Show visual feedback
    this.showCallFeedback(event.currentTarget)
    
    // Track the call attempt via AJAX (after call is triggered)
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
      console.log('Call tracked successfully:', data)
    })
    .catch(error => {
      console.error('Failed to track call:', error)
    })
  }

  showCallFeedback(callBtn) {
    const originalText = callBtn.innerHTML
    const originalStyle = {
      background: callBtn.style.background,
      color: callBtn.style.color
    }
    
    // Show "calling" state
    callBtn.innerHTML = '<i class="fas fa-phone-alt"></i> Calling...'
    callBtn.style.background = '#dbeafe'
    callBtn.style.color = '#1e40af'
    
    // Reset after delay
    setTimeout(() => {
      callBtn.innerHTML = originalText
      callBtn.style.background = originalStyle.background
      callBtn.style.color = originalStyle.color
    }, 3000)
  }
}