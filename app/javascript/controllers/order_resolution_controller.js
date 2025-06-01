import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "customerForm", "form"]
  static values = { expanded: Boolean }

  connect() {
    console.log("Order resolution controller connected")
  }

  toggleResolution(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const panel = this.panelTarget
    const button = event.currentTarget
    
    if (this.expandedValue) {
      // Collapse
      panel.style.display = "none"
      button.innerHTML = '<i class="fas fa-tools"></i>'
      button.title = "Resolve Issue"
      button.classList.remove("expanded")
      this.expandedValue = false
      this.element.classList.remove("expanded")
    } else {
      // Expand
      panel.style.display = "block"
      button.innerHTML = '<i class="fas fa-times"></i>'
      button.title = "Close"
      button.classList.add("expanded")
      this.expandedValue = true
      this.element.classList.add("expanded")
    }
  }

  showCustomerForm(event = null) {
    if (event) event.preventDefault()
    this.customerFormTarget.style.display = "block"
    this.customerFormTarget.querySelector('textarea').focus()
  }

  hideCustomerForm(event = null) {
    if (event) event.preventDefault()
    this.customerFormTarget.style.display = "none"
  }

  submitNotes(event) {
    // Let the form submit normally via Turbo
    // Hide the form after successful submission
    setTimeout(() => {
      if (this.hasCustomerFormTarget) {
        this.customerFormTarget.style.display = "none"
      }
    }, 100)
  }

  async contactCustomerDelay(event) {
    event.preventDefault()
    
    if (!confirm("Contact customer about shipping delay? This will update the resolution stage.")) {
      return
    }

    try {
      const dispatchId = event.currentTarget.dataset.dispatchId
      if (!dispatchId) {
        this.showError('No dispatch found for this order')
        return
      }

      const response = await fetch(`/dispatches/${dispatchId}/contact_customer_delay`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      })

      const result = await response.json()
      
      if (result.success) {
        this.showSuccess('Customer contacted about shipping delay. Record their response below.')
        this.showCustomerForm()
        // Don't refresh card immediately - let user fill out the form first
      } else {
        this.showError(result.message || 'Failed to contact customer')
      }
    } catch (error) {
      console.error('Error contacting customer:', error)
      this.showError('Failed to contact customer')
    }
  }

  async contactCustomerPriceIncrease(event) {
    event.preventDefault()
    
    const priceDifference = event.currentTarget.dataset.priceDifference
    if (!confirm(`Contact customer about $${priceDifference} price increase? This will update the resolution stage.`)) {
      return
    }

    try {
      const dispatchId = event.currentTarget.dataset.dispatchId
      if (!dispatchId) {
        this.showError('No dispatch found for this order')
        return
      }

      const response = await fetch(`/dispatches/${dispatchId}/contact_customer_price_increase`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          price_difference: priceDifference
        })
      })

      const result = await response.json()
      
      if (result.success) {
        this.showSuccess(`Customer contacted about $${priceDifference} price increase. Record their response below.`)
        this.showCustomerForm()
        // Don't refresh card immediately - let user fill out the form first
      } else {
        this.showError(result.message || 'Failed to contact customer')
      }
    } catch (error) {
      console.error('Error contacting customer:', error)
      this.showError('Failed to contact customer')
    }
  }

  async createReplacement(event) {
    event.preventDefault()
    
    if (!confirm("Create a replacement order?")) {
      return
    }

    try {
      const dispatchId = event.currentTarget.dataset.dispatchId
      if (!dispatchId) {
        this.showError('No dispatch found for this order')
        return
      }

      const response = await fetch(`/dispatches/${dispatchId}/create_replacement_order_from_resolution`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      })

      const result = await response.json()
      
      if (result.success) {
        this.showSuccess(result.message)
        this.refreshOrderCard()
      } else {
        this.showError(result.message || 'Failed to create replacement order')
      }
    } catch (error) {
      console.error('Error creating replacement:', error)
      this.showError('Failed to create replacement order')
    }
  }

  async processRefund(event) {
    event.preventDefault()
    
    if (!confirm("Process full refund and cancel order?")) {
      return
    }

    try {
      const dispatchId = event.currentTarget.dataset.dispatchId
      if (!dispatchId) {
        this.showError('No dispatch found for this order')
        return
      }

      const response = await fetch(`/dispatches/${dispatchId}/process_full_refund_from_resolution`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      })

      const result = await response.json()
      
      if (result.success) {
        this.showSuccess(result.message)
        this.refreshOrderCard()
      } else {
        this.showError(result.message || 'Failed to process refund')
      }
    } catch (error) {
      console.error('Error processing refund:', error)
      this.showError('Failed to process refund')
    }
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  showSuccess(message) {
    // Create a temporary success message
    const alert = document.createElement('div')
    alert.className = 'alert alert-success'
    alert.textContent = message
    alert.style.position = 'fixed'
    alert.style.top = '20px'
    alert.style.right = '20px'
    alert.style.zIndex = '9999'
    
    document.body.appendChild(alert)
    
    setTimeout(() => {
      alert.remove()
    }, 3000)
  }

  showError(message) {
    // Create a temporary error message
    const alert = document.createElement('div')
    alert.className = 'alert alert-danger'
    alert.textContent = message
    alert.style.position = 'fixed'
    alert.style.top = '20px'
    alert.style.right = '20px'
    alert.style.zIndex = '9999'
    
    document.body.appendChild(alert)
    
    setTimeout(() => {
      alert.remove()
    }, 3000)
  }

  refreshOrderCard() {
    // Use turbo frames to refresh content instead of full page reload
    const ordersFrame = document.querySelector('turbo-frame[id="orders-frame"]')
    if (ordersFrame && ordersFrame.src) {
      // Refresh the orders frame to show updated status
      ordersFrame.reload()
    } else {
      // Fallback: refresh main content frame
      const mainFrame = document.querySelector('turbo-frame[id="main_content"]')
      if (mainFrame && mainFrame.src) {
        mainFrame.reload()
      } else {
        // Last resort: use turbo visit to orders index
        setTimeout(() => {
          window.Turbo.visit('/orders', { frame: 'main_content' })
        }, 1000)
      }
    }
  }
}