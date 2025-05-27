import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["orderSelect", "customerName", "customerEmail", "originalAmount", "refundAmount", "refundPercentage", "progressBar"]

  connect() {
    console.log("Refund form controller connected")
    this.calculatePercentage()
  }

  // Handle order selection change
  orderChanged() {
    const orderId = this.orderSelectTarget.value
    
    if (!orderId) {
      this.clearOrderData()
      return
    }

    // Fetch order data via AJAX
    fetch(`/orders/${orderId}/get_order_details`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.error) {
        console.error('Error fetching order data:', data.error)
        return
      }
      
      this.populateOrderData(data)
    })
    .catch(error => {
      console.error('Error:', error)
    })
  }

  // Populate form with order data
  populateOrderData(orderData) {
    if (this.hasCustomerNameTarget) {
      this.customerNameTarget.value = orderData.customer_name || ''
    }
    
    if (this.hasCustomerEmailTarget) {
      this.customerEmailTarget.value = orderData.customer_email || ''
    }
    
    if (this.hasOriginalAmountTarget) {
      this.originalAmountTarget.value = orderData.total_amount || 0
    }
    
    // Set refund amount to full amount by default
    if (this.hasRefundAmountTarget) {
      this.refundAmountTarget.value = orderData.total_amount || 0
    }
    
    this.calculatePercentage()
  }

  // Clear order data
  clearOrderData() {
    if (this.hasCustomerNameTarget) {
      this.customerNameTarget.value = ''
    }
    
    if (this.hasCustomerEmailTarget) {
      this.customerEmailTarget.value = ''
    }
    
    if (this.hasOriginalAmountTarget) {
      this.originalAmountTarget.value = ''
    }
    
    if (this.hasRefundAmountTarget) {
      this.refundAmountTarget.value = ''
    }
    
    this.calculatePercentage()
  }

  // Calculate refund percentage
  calculatePercentage() {
    const originalAmount = parseFloat(this.hasOriginalAmountTarget ? this.originalAmountTarget.value : 0) || 0
    const refundAmount = parseFloat(this.hasRefundAmountTarget ? this.refundAmountTarget.value : 0) || 0
    
    let percentage = 0
    if (originalAmount > 0) {
      percentage = (refundAmount / originalAmount) * 100
    }
    
    // Cap at 100%
    percentage = Math.min(percentage, 100)
    
    // Update percentage display
    if (this.hasRefundPercentageTarget) {
      this.refundPercentageTarget.textContent = `${percentage.toFixed(1)}%`
    }
    
    // Update progress bar
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percentage}%`
      
      // Change color based on percentage
      this.progressBarTarget.className = 'progress-bar'
      if (percentage >= 90) {
        this.progressBarTarget.classList.add('bg-warning')
      } else if (percentage >= 50) {
        this.progressBarTarget.classList.add('bg-success')
      } else {
        this.progressBarTarget.classList.add('bg-info')
      }
    }
  }

  // Validate refund amount
  validateRefundAmount() {
    const originalAmount = parseFloat(this.hasOriginalAmountTarget ? this.originalAmountTarget.value : 0) || 0
    const refundAmount = parseFloat(this.hasRefundAmountTarget ? this.refundAmountTarget.value : 0) || 0
    
    if (refundAmount > originalAmount) {
      alert('Refund amount cannot exceed original charge amount')
      if (this.hasRefundAmountTarget) {
        this.refundAmountTarget.value = originalAmount
      }
      this.calculatePercentage()
    }
    
    if (refundAmount < 0) {
      alert('Refund amount cannot be negative')
      if (this.hasRefundAmountTarget) {
        this.refundAmountTarget.value = 0
      }
      this.calculatePercentage()
    }
  }

  // Quick percentage buttons
  setPercentage(event) {
    const percentage = parseInt(event.currentTarget.dataset.percentage)
    const originalAmount = parseFloat(this.hasOriginalAmountTarget ? this.originalAmountTarget.value : 0) || 0
    
    if (originalAmount > 0) {
      const refundAmount = (originalAmount * percentage) / 100
      if (this.hasRefundAmountTarget) {
        this.refundAmountTarget.value = refundAmount.toFixed(2)
      }
      this.calculatePercentage()
    }
  }

  // Form submission validation
  submitForm(event) {
    const originalAmount = parseFloat(this.hasOriginalAmountTarget ? this.originalAmountTarget.value : 0) || 0
    const refundAmount = parseFloat(this.hasRefundAmountTarget ? this.refundAmountTarget.value : 0) || 0
    
    if (refundAmount <= 0) {
      event.preventDefault()
      alert('Please enter a valid refund amount')
      return false
    }
    
    if (refundAmount > originalAmount) {
      event.preventDefault()
      alert('Refund amount cannot exceed original charge amount')
      return false
    }
    
    // Show loading state
    const submitBtn = event.target.querySelector('input[type="submit"]')
    if (submitBtn) {
      submitBtn.disabled = true
      submitBtn.value = 'Creating Refund...'
    }
    
    return true
  }
}