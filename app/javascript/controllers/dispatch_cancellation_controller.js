import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statusSelect", "cancellationModal", "reasonSelect", "customReason", "priceIncrease", "priceIncreaseAmount", "refundAmount"]
  static values = { 
    originalAmount: Number,
    dispatchId: Number
  }

  connect() {
    console.log("Dispatch cancellation controller connected")
  }

  disconnect() {
    // Ensure scrolling is always restored when controller is removed
    this.restoreBodyScrolling()
    console.log("Dispatch cancellation controller disconnected - scrolling restored")
  }

  statusChanged() {
    const selectedStatus = this.statusSelectTarget.value
    console.log("Status changed to:", selectedStatus)
    
    if (selectedStatus === 'cancelled') {
      // Prevent the form from submitting and show modal
      console.log("Cancelled selected, showing modal")
      this.showCancellationModal()
    }
  }

  showCancellationModal() {
    console.log("showCancellationModal called")
    
    // Store the original status value before showing modal
    if (this.hasStatusSelectTarget) {
      this.statusSelectTarget.dataset.originalValue = this.statusSelectTarget.value
    }
    
    // Pre-populate the refund amount with original amount
    if (this.hasRefundAmountTarget && this.originalAmountValue) {
      this.refundAmountTarget.value = this.originalAmountValue.toFixed(2)
      console.log("Refund amount set to:", this.originalAmountValue)
    }
    
    // Show the modern modal with animation
    if (this.hasCancellationModalTarget) {
      console.log("Modal target found, showing modern modal")
      
      // Prevent body scrolling while modal is open
      this.preventBodyScrolling()
      
      // Show modal with fade-in animation
      this.cancellationModalTarget.style.display = 'flex'
      this.cancellationModalTarget.classList.add('modal-show')
      
      // Add fade-in animation
      requestAnimationFrame(() => {
        this.cancellationModalTarget.classList.add('modal-visible')
        // Initialize the percentage meter
        this.updateRefundPercentage()
      })
    } else {
      console.log("Modal target not found!")
    }
  }

  preventBodyScrolling() {
    // Prevent background scrolling while modal is open
    document.body.classList.add('modal-open')
    document.body.style.overflow = 'hidden'
    
    // Store current scroll position to restore later
    this.scrollPosition = window.pageYOffset || document.documentElement.scrollTop
  }

  reasonChanged() {
    const selectedReason = this.reasonSelectTarget.value
    
    // Show custom reason input if "other" is selected
    if (this.hasCustomReasonTarget) {
      if (selectedReason === 'other') {
        this.customReasonTarget.style.display = 'block'
      } else {
        this.customReasonTarget.style.display = 'none'
      }
    }
    
    // Show price increase input if "item_not_found" (price increase) is selected
    if (this.hasPriceIncreaseTarget) {
      if (selectedReason === 'item_not_found') {
        this.priceIncreaseTarget.style.display = 'block'
      } else {
        this.priceIncreaseTarget.style.display = 'none'
      }
    }
  }

  refundAmountChanged() {
    this.updateRefundPercentage()
  }

  updateRefundPercentage() {
    if (!this.hasRefundAmountTarget || !this.originalAmountValue) {
      return
    }

    const refundAmount = parseFloat(this.refundAmountTarget.value) || 0
    const originalAmount = this.originalAmountValue
    
    // Calculate percentage
    const percentage = originalAmount > 0 ? (refundAmount / originalAmount * 100) : 0
    const clampedPercentage = Math.max(0, Math.min(100, percentage))
    
    // Update percentage display
    const percentageDisplay = document.getElementById('refund-percentage-display')
    const progressBar = document.getElementById('refund-progress-bar')
    
    if (percentageDisplay) {
      percentageDisplay.textContent = `${clampedPercentage.toFixed(1)}%`
      
      // Add color coding based on percentage
      percentageDisplay.className = 'modern-percentage-value'
      if (clampedPercentage >= 90) {
        percentageDisplay.classList.add('percentage-full')
      } else if (clampedPercentage >= 50) {
        percentageDisplay.classList.add('percentage-partial')
      } else {
        percentageDisplay.classList.add('percentage-minimal')
      }
    }
    
    if (progressBar) {
      progressBar.style.width = `${clampedPercentage}%`
      
      // Update progress bar color based on percentage
      progressBar.className = 'modern-percentage-fill'
      if (clampedPercentage >= 90) {
        progressBar.classList.add('fill-full')
      } else if (clampedPercentage >= 50) {
        progressBar.classList.add('fill-partial')
      } else {
        progressBar.classList.add('fill-minimal')
      }
    }
    
    // Add bounce animation on change
    if (percentageDisplay) {
      percentageDisplay.classList.add('percentage-bounce')
      setTimeout(() => {
        percentageDisplay.classList.remove('percentage-bounce')
      }, 300)
    }
  }

  confirmCancellation() {
    const reason = this.reasonSelectTarget.value
    const customReason = this.customReasonTarget.querySelector('input').value
    const refundAmount = parseFloat(this.refundAmountTarget.value) || 0
    const priceIncrease = this.hasPriceIncreaseAmountTarget ? parseFloat(this.priceIncreaseAmountTarget.value) || 0 : 0
    
    // Validate inputs
    if (!reason) {
      alert('Please select an agent action')
      return
    }
    
    if (reason === 'other' && !customReason.trim()) {
      alert('Please provide a custom reason')
      return
    }
    
    if (reason === 'item_not_found' && priceIncrease <= 0) {
      alert('Please specify the price increase amount')
      return
    }
    
    if (refundAmount < 0) {
      alert('Refund amount cannot be negative')
      return
    }
    
    if (refundAmount > this.originalAmountValue) {
      alert('Refund amount cannot exceed original charge amount')
      return
    }
    
    // Prepare the cancellation data
    const cancellationData = {
      reason: reason === 'other' ? customReason.trim() : reason,
      refund_amount: refundAmount,
      price_difference: priceIncrease,
      dispatch_status: 'cancelled'
    }
    
    // Submit the cancellation via AJAX
    this.submitCancellation(cancellationData)
  }

  async submitCancellation(data) {
    try {
      const response = await fetch(`/dispatches/${this.dispatchIdValue}/cancel_with_reason`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify(data)
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const contentType = response.headers.get('content-type')
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Response is not JSON')
      }
      
      const result = await response.json()
      
      if (result.success) {
        // First hide the modal properly
        this.hideModalImmediate()
        
        // Wait a moment for any UI cleanup, then navigate
        setTimeout(() => {
          const redirectUrl = result.redirect_url || '/dispatches'
          if (window.Turbo) {
            window.Turbo.visit(redirectUrl, { frame: 'main_content' })
          } else {
            window.location.href = redirectUrl
          }
        }, 100)
      } else {
        alert(result.message || 'Failed to cancel dispatch')
      }
    } catch (error) {
      console.error('Error cancelling dispatch:', error)
      alert('An error occurred while cancelling the dispatch')
    }
  }

  hideModal() {
    console.log("Hiding modal with animation")
    
    if (!this.hasCancellationModalTarget) return
    
    // Hide the modern modal with animation
    this.cancellationModalTarget.classList.remove('modal-visible')
    
    // Wait for animation to complete before hiding
    setTimeout(() => {
      this.cancellationModalTarget.style.display = 'none'
      this.cancellationModalTarget.classList.remove('modal-show')
      this.restoreBodyScrolling()
    }, 300)
  }

  hideModalImmediate() {
    console.log("Hiding modal immediately")
    
    if (!this.hasCancellationModalTarget) return
    
    // Hide modal immediately without animation for smooth navigation
    this.cancellationModalTarget.style.display = 'none'
    this.cancellationModalTarget.classList.remove('modal-visible', 'modal-show')
    this.restoreBodyScrolling()
  }

  restoreBodyScrolling() {
    // Use global function if available, otherwise restore locally
    if (window.restorePageScrolling) {
      window.restorePageScrolling()
    } else {
      // Fallback: Remove modal-open class and restore scrolling
      document.body.classList.remove('modal-open')
      document.body.style.overflow = ''
      document.body.style.overflowY = ''
      document.body.style.paddingRight = ''
      document.body.style.position = ''
      document.body.style.top = ''
      document.body.style.width = ''
      
      // Also restore on html element in case it was affected
      document.documentElement.style.overflow = ''
      document.documentElement.style.overflowY = ''
      
      console.log('Page scrolling restored (fallback)')
    }
  }

  cancelModal() {
    console.log("Cancel modal called")
    
    // Reset the status dropdown to its previous value
    if (this.hasStatusSelectTarget) {
      this.statusSelectTarget.value = this.statusSelectTarget.dataset.originalValue || 'pending'
    }
    
    // Hide the modal with animation
    this.hideModal()
  }

  // Store original value when page loads
  storeOriginalStatus() {
    this.statusSelectTarget.dataset.originalValue = this.statusSelectTarget.value
  }
}