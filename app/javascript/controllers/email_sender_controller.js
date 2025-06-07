import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    orderId: Number, 
    emailType: String 
  }

  connect() {
    console.log("✅ Email sender controller connected", {
      orderId: this.orderIdValue,
      emailType: this.emailTypeValue
    })
  }

  async sendEmail(event) {
    console.log("🔘 Send email button clicked!", event)
    
    const button = event.currentTarget
    const originalText = button.innerHTML
    const orderId = this.orderIdValue
    const emailType = this.emailTypeValue
    
    console.log("📧 Sending email:", { orderId, emailType })

    // Disable button and show loading state
    button.disabled = true
    button.innerHTML = `<i class="fas fa-spinner fa-spin"></i> Sending...`
    button.classList.add('btn-secondary')
    button.classList.remove('btn-success', 'btn-info', 'btn-warning')

    try {
      const response = await fetch(`/email_actions/send_order_email`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          order_id: orderId,
          email_type: emailType
        })
      })

      const data = await response.json()

      if (data.success) {
        // Show success state
        button.innerHTML = `<i class="fas fa-check"></i> Sent!`
        button.classList.add('btn-success')
        button.classList.remove('btn-secondary')
        
        // Show success toast
        this.showToast(data.message, 'success')
        
        // Update email status indicator
        this.updateEmailStatus(emailType, 'success', data.message)
        
        // Reset button after 3 seconds
        setTimeout(() => {
          button.disabled = false
          button.innerHTML = originalText
          button.classList.remove('btn-success')
          button.classList.add(this.getOriginalButtonClass(emailType))
        }, 3000)
        
      } else {
        // Show error state
        button.innerHTML = `<i class="fas fa-exclamation-triangle"></i> Failed`
        button.classList.add('btn-danger')
        button.classList.remove('btn-secondary')
        
        // Show error toast
        this.showToast(data.error || 'Failed to send email', 'error')
        
        // Update email status indicator
        this.updateEmailStatus(emailType, 'error', data.error)
        
        // Reset button after 5 seconds
        setTimeout(() => {
          button.disabled = false
          button.innerHTML = originalText
          button.classList.remove('btn-danger')
          button.classList.add(this.getOriginalButtonClass(emailType))
        }, 5000)
      }
      
    } catch (error) {
      console.error('Email send error:', error)
      
      // Show error state
      button.innerHTML = `<i class="fas fa-exclamation-triangle"></i> Error`
      button.classList.add('btn-danger')
      button.classList.remove('btn-secondary')
      
      // Show error toast
      this.showToast('Network error - please try again', 'error')
      
      // Reset button after 5 seconds
      setTimeout(() => {
        button.disabled = false
        button.innerHTML = originalText
        button.classList.remove('btn-danger')
        button.classList.add(this.getOriginalButtonClass(emailType))
      }, 5000)
    }
  }

  getOriginalButtonClass(emailType) {
    switch (emailType) {
      case 'confirmation':
        return 'btn-success'
      case 'shipping_notification':
        return 'btn-info'
      case 'follow_up':
        return 'btn-warning'
      default:
        return 'btn-primary'
    }
  }

  updateEmailStatus(emailType, status, message) {
    const statusElement = document.getElementById(`email-status-${this.orderIdValue}`)
    if (!statusElement) return

    const statusIcon = status === 'success' ? 'fas fa-check-circle text-success' : 'fas fa-exclamation-triangle text-danger'
    const timestamp = new Date().toLocaleTimeString()
    
    statusElement.style.display = 'block'
    statusElement.innerHTML = `
      <div class="alert alert-${status === 'success' ? 'success' : 'danger'} alert-dismissible fade show" role="alert">
        <i class="${statusIcon}"></i>
        <strong>${emailType.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())} Email:</strong> ${message}
        <small class="d-block mt-1">Sent at ${timestamp}</small>
        <button type="button" class="btn-close" onclick="this.parentElement.remove()"></button>
      </div>
    `
  }

  showToast(message, type) {
    // Create a simple notification instead of Bootstrap toast
    const toastContainer = this.getOrCreateToastContainer()
    const toastId = `toast-${Date.now()}`
    const bgClass = type === 'success' ? 'bg-success' : 'bg-danger'
    const icon = type === 'success' ? 'fas fa-check-circle' : 'fas fa-exclamation-triangle'
    
    const toastHtml = `
      <div id="${toastId}" class="alert alert-${type === 'success' ? 'success' : 'danger'} alert-dismissible fade show" role="alert" style="margin-bottom: 10px;">
        <i class="${icon}"></i>
        ${message}
        <button type="button" class="btn-close" onclick="this.parentElement.remove()"></button>
      </div>
    `
    
    toastContainer.insertAdjacentHTML('beforeend', toastHtml)
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      const toastElement = document.getElementById(toastId)
      if (toastElement) {
        toastElement.style.opacity = '0'
        setTimeout(() => toastElement.remove(), 300)
      }
    }, 5000)
  }

  getOrCreateToastContainer() {
    let container = document.getElementById('toast-container')
    if (!container) {
      container = document.createElement('div')
      container.id = 'toast-container'
      container.className = 'toast-container position-fixed top-0 end-0 p-3'
      container.style.zIndex = '9999'
      document.body.appendChild(container)
    }
    return container
  }
}