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
}