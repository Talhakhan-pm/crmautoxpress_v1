import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", "overlay", "form", "productPrice", "taxAmount", 
    "shippingCost", "totalAmount", "totalDisplay", "selectedCallbackId",
    "customerName", "customerPhone", "customerEmail", "customerAddress",
    "productName", "carYear", "carMakeModel"
  ]
  
  static values = { 
    callbackId: Number,
    orderType: String 
  }

  connect() {
    this.calculateTotal()
    this.checkForCallback()
  }

  checkForCallback() {
    const callbackId = this.callbackIdValue
    
    if (callbackId) {
      // Auto-switch to conversion mode
      const conversionBtn = this.element.querySelector('[data-type="conversion"]')
      if (conversionBtn) {
        conversionBtn.click()
      }
      
      // Auto-select the callback
      const callbackCard = this.element.querySelector(`[data-callback-id="${callbackId}"]`)
      if (callbackCard) {
        callbackCard.click()
      }
    }
  }

  setOrderType(event) {
    const type = event.currentTarget.dataset.type
    
    // Update toggle buttons
    this.element.querySelectorAll('.toggle-btn').forEach(btn => {
      btn.classList.remove('active')
    })
    event.currentTarget.classList.add('active')
    
    // Show/hide callback selection
    const callbackSection = this.element.querySelector('#callback-selection')
    if (type === 'conversion') {
      callbackSection.style.display = 'block'
    } else {
      callbackSection.style.display = 'none'
      if (this.hasSelectedCallbackIdTarget) {
        this.selectedCallbackIdTarget.value = ''
      }
      this.clearForm()
    }
  }

  selectCallback(event) {
    const callbackId = event.params.callbackId
    
    // Update UI
    this.element.querySelectorAll('.callback-card').forEach(card => {
      card.classList.remove('selected')
    })
    event.currentTarget.classList.add('selected')
    
    // Store selection
    if (this.hasSelectedCallbackIdTarget) {
      this.selectedCallbackIdTarget.value = callbackId
    }
    
    // Populate form with callback data
    fetch(`/callbacks/${callbackId}.json`)
      .then(response => response.json())
      .then(callback => {
        if (this.hasCustomerNameTarget) this.customerNameTarget.value = callback.customer_name || ''
        if (this.hasCustomerPhoneTarget) this.customerPhoneTarget.value = callback.phone_number || ''
        if (this.hasProductNameTarget) this.productNameTarget.value = callback.product || ''
        if (this.hasCarYearTarget) this.carYearTarget.value = callback.year || ''
        if (this.hasCarMakeModelTarget) this.carMakeModelTarget.value = callback.car_make_model || ''
        
        // Focus on pricing since customer/product data is populated
        if (this.hasProductPriceTarget) this.productPriceTarget.focus()
      })
      .catch(error => console.error('Error fetching callback:', error))
  }

  searchCallbacks(event) {
    const query = event.target.value.trim()
    if (!query) return
    
    // Simple client-side search
    const cards = this.element.querySelectorAll('.callback-card')
    cards.forEach(card => {
      const text = card.textContent.toLowerCase()
      const matches = text.includes(query.toLowerCase())
      card.style.display = matches ? 'block' : 'none'
    })
  }

  calculateTotal() {
    const price = parseFloat(this.productPriceTarget?.value) || 0
    const tax = parseFloat(this.taxAmountTarget?.value) || 0
    const shipping = parseFloat(this.shippingCostTarget?.value) || 0
    
    const total = price + tax + shipping
    
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = `$${total.toFixed(2)}`
    }
    if (this.hasTotalAmountTarget) {
      this.totalAmountTarget.value = total.toFixed(2)
    }
  }

  lookupCustomer() {
    const modal = document.getElementById('customer-lookup')
    modal.classList.add('active')
    
    fetch('/customers.json')
      .then(response => response.json())
      .then(customers => {
        const list = document.getElementById('customers-list')
        list.innerHTML = customers.map(customer => `
          <div class="lookup-item" data-action="click->order-form#selectCustomer" 
               data-name="${customer.name}" 
               data-phone="${customer.phone_number}" 
               data-email="${customer.email || ''}" 
               data-address="${customer.address || ''}">
            <strong>${customer.name}</strong><br>
            <small>${customer.phone_number}</small>
          </div>
        `).join('')
      })
  }

  lookupProduct() {
    const modal = document.getElementById('product-lookup')
    modal.classList.add('active')
    
    fetch('/products.json')
      .then(response => response.json())
      .then(products => {
        const list = document.getElementById('products-list')
        list.innerHTML = products.map(product => `
          <div class="lookup-item" data-action="click->order-form#selectProduct"
               data-name="${product.name}" 
               data-price="${product.selling_price || 0}">
            <strong>${product.name}</strong><br>
            <small>$${product.selling_price || 'N/A'}</small>
          </div>
        `).join('')
      })
  }

  selectCustomer(event) {
    const item = event.currentTarget
    if (this.hasCustomerNameTarget) this.customerNameTarget.value = item.dataset.name
    if (this.hasCustomerPhoneTarget) this.customerPhoneTarget.value = item.dataset.phone
    if (this.hasCustomerEmailTarget) this.customerEmailTarget.value = item.dataset.email
    if (this.hasCustomerAddressTarget) this.customerAddressTarget.value = item.dataset.address
    this.closeLookupModal('customer')
  }

  selectProduct(event) {
    const item = event.currentTarget
    if (this.hasProductNameTarget) this.productNameTarget.value = item.dataset.name
    if (this.hasProductPriceTarget) this.productPriceTarget.value = item.dataset.price
    this.calculateTotal()
    this.closeLookupModal('product')
  }

  closeLookupModal(type) {
    document.getElementById(`${type}-lookup`).classList.remove('active')
  }

  clearForm() {
    this.formTarget.reset()
    this.calculateTotal()
  }

  closeModal() {
    this.modalTarget.classList.remove('active')
    this.clearForm()
    
    // Go back to previous page if this was opened from callbacks
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.get('callback_id')) {
      window.history.back()
    }
  }

  submitForm(event) {
    // Add loading state
    const submitBtn = event.target.querySelector('[type="submit"]:focus')
    if (submitBtn) {
      const originalText = submitBtn.innerHTML
      submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creating...'
      submitBtn.disabled = true
      
      // Store original button state for error handling
      this.originalSubmitState = {
        button: submitBtn,
        text: originalText
      }
    }
  }

  // Handle form submission completion (success or error)
  handleSubmitEnd(event) {
    console.log('Form submission completed:', event.detail)
    
    // Check if the submission was successful
    const response = event.detail.fetchResponse?.response
    
    if (response && response.ok) {
      this.handleSuccess(event)
    } else {
      this.handleError(event)
    }
  }

  // Handle successful form submission
  handleSuccess(event) {
    console.log('Order created successfully!')
    
    // Reset button state
    this.resetSubmitButton()
    
    // Show success feedback
    this.showNotification('Order created successfully!', 'success')
    
    // Close modal and redirect after a short delay
    setTimeout(() => {
      this.closeModal()
      
      // Redirect to orders page
      window.location.href = '/orders'
    }, 1500)
  }

  // Handle form submission errors
  handleError(event) {
    console.error('Order creation failed:', event.detail)
    
    // Reset button state
    this.resetSubmitButton()
    
    // Show error feedback
    this.showNotification('Failed to create order. Please try again.', 'error')
  }

  // Handle Turbo fetch errors
  handleFetchError(event) {
    console.error('Network error during form submission:', event.detail)
    
    // Reset button state
    this.resetSubmitButton()
    
    // Show network error feedback
    this.showNotification('Network error. Please check your connection and try again.', 'error')
  }

  // Reset submit button to original state
  resetSubmitButton() {
    if (this.originalSubmitState) {
      this.originalSubmitState.button.innerHTML = this.originalSubmitState.text
      this.originalSubmitState.button.disabled = false
      this.originalSubmitState = null
    }
  }

  // Show notification to user
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
    }, 3000)
  }
}