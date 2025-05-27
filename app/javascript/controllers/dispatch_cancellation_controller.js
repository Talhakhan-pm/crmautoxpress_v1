import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statusSelect", "cancellationModal", "reasonSelect", "customReason", "refundAmount"]
  static values = { 
    originalAmount: Number,
    dispatchId: Number
  }

  connect() {
    console.log("Dispatch cancellation controller connected")
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
    
    // Pre-populate the refund amount with original amount
    if (this.hasRefundAmountTarget && this.originalAmountValue) {
      this.refundAmountTarget.value = this.originalAmountValue.toFixed(2)
      console.log("Refund amount set to:", this.originalAmountValue)
    }
    
    // Show the modal - try different approaches
    if (this.hasCancellationModalTarget) {
      console.log("Modal target found, trying to show")
      
      // Try Bootstrap 5 approach first
      try {
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
          const modal = new bootstrap.Modal(this.cancellationModalTarget)
          modal.show()
          console.log("Bootstrap modal shown")
        } else {
          // Fallback: show manually
          console.log("Bootstrap not available, showing manually")
          this.cancellationModalTarget.style.display = 'block'
          this.cancellationModalTarget.classList.add('show')
          document.body.classList.add('modal-open')
        }
      } catch (error) {
        console.error("Error showing modal:", error)
        // Fallback: show manually
        this.cancellationModalTarget.style.display = 'block'
        this.cancellationModalTarget.classList.add('show')
        document.body.classList.add('modal-open')
      }
    } else {
      console.log("Modal target not found!")
    }
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
  }

  confirmCancellation() {
    const reason = this.reasonSelectTarget.value
    const customReason = this.customReasonTarget.querySelector('input').value
    const refundAmount = parseFloat(this.refundAmountTarget.value) || 0
    
    // Validate inputs
    if (!reason) {
      alert('Please select a cancellation reason')
      return
    }
    
    if (reason === 'other' && !customReason.trim()) {
      alert('Please provide a custom reason')
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
        // Hide modal and redirect or update UI
        this.hideModal()
        
        // Show success message and redirect
        if (result.redirect_url) {
          window.location.href = result.redirect_url
        } else {
          location.reload()
        }
      } else {
        alert(result.message || 'Failed to cancel dispatch')
      }
    } catch (error) {
      console.error('Error cancelling dispatch:', error)
      alert('An error occurred while cancelling the dispatch')
    }
  }

  hideModal() {
    console.log("Hiding modal")
    
    // Hide the modal
    try {
      if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
        const modal = bootstrap.Modal.getInstance(this.cancellationModalTarget)
        if (modal) {
          modal.hide()
        }
      } else {
        // Manual hide
        this.cancellationModalTarget.style.display = 'none'
        this.cancellationModalTarget.classList.remove('show')
        document.body.classList.remove('modal-open')
      }
    } catch (error) {
      console.error("Error hiding modal:", error)
      // Fallback: hide manually
      this.cancellationModalTarget.style.display = 'none'
      this.cancellationModalTarget.classList.remove('show')
      document.body.classList.remove('modal-open')
    }
  }

  cancelModal() {
    console.log("Cancel modal called")
    
    // Reset the status dropdown to its previous value
    this.statusSelectTarget.value = this.statusSelectTarget.dataset.originalValue || 'pending'
    
    // Hide the modal
    this.hideModal()
  }

  // Store original value when page loads
  storeOriginalStatus() {
    this.statusSelectTarget.dataset.originalValue = this.statusSelectTarget.value
  }
}