import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dispatch-form"
export default class extends Controller {
  static targets = [
    "modal", "form", "orderSelect", "orderNumber", "customerName", 
    "productName", "carDetails", "productCost", "productCostDisplay", "taxAmount", "shippingCost", 
    "totalCost", "totalDisplay", "customerTotal", "supplierName", "supplierOrderNumber", 
    "supplierCost", "supplierCostDisplay", "profitDisplay", "profitMargin",
    "trackingSection", "dispatchStatus", "trackingNumber", "trackingLink"
  ]
  
  static values = { 
    profitCalculator: Boolean 
  }

  connect() {
    console.log('Dispatch form controller connected')
    
    // Initialize profit calculation on connect
    this.calculateProfit()
    
    // Set up keyboard shortcuts
    this.setupKeyboardShortcuts()
    
    // Set up real-time listeners
    this.setupRealTimeListeners()
  }

  disconnect() {
    // Controller disconnected
  }

  // Set up real-time listeners for profit calculation
  setupRealTimeListeners() {
    // Listen for supplier cost changes
    if (this.hasSupplierCostTarget) {
      this.supplierCostTarget.addEventListener('input', () => {
        this.calculateProfit()
      })
      this.supplierCostTarget.addEventListener('keyup', () => {
        this.calculateProfit()
      })
    }
  }

  // Keyboard shortcuts for faster workflow
  setupKeyboardShortcuts() {
    document.addEventListener('keydown', (event) => {
      // ESC to close modal
      if (event.key === 'Escape') {
        this.closeModal()
      }
      
      // Ctrl/Cmd + S to save
      if ((event.ctrlKey || event.metaKey) && event.key === 's') {
        event.preventDefault()
        this.submitForm()
      }
    })
  }

  // Close modal and navigate back
  closeModal() {
    if (this.hasModalTarget) {
      // Add closing animation
      this.modalTarget.style.opacity = '0'
      this.modalTarget.style.transform = 'scale(0.95)'
      
      setTimeout(() => {
        window.location.href = '/dispatches'
      }, 200)
    }
  }

  // Order selection for new dispatches (if needed)
  populateOrderData(event) {
    const orderId = event.target.value
    if (!orderId) {
      this.clearOrderData()
      return
    }

    // Fetch order data via AJAX
    fetch(`/orders/${orderId}.json`)
      .then(response => response.json())
      .then(data => {
        this.fillOrderData(data)
      })
      .catch(error => {
        console.error('Error fetching order data:', error)
        this.showError('Failed to load order data')
      })
  }

  fillOrderData(orderData) {
    if (this.hasOrderNumberTarget) {
      this.orderNumberTarget.value = orderData.order_number
    }
    if (this.hasCustomerNameTarget) {
      this.customerNameTarget.value = orderData.customer_name
    }
    if (this.hasProductNameTarget) {
      this.productNameTarget.value = orderData.product_name
    }
    if (this.hasCarDetailsTarget) {
      this.carDetailsTarget.value = orderData.vehicle_info || ''
    }
    if (this.hasProductCostTarget) {
      this.productCostTarget.value = orderData.product_price
    }
    if (this.hasTaxAmountTarget) {
      this.taxAmountTarget.value = orderData.tax_amount || 0
    }
    if (this.hasShippingCostTarget) {
      this.shippingCostTarget.value = orderData.shipping_cost || 0
    }
    if (this.hasTotalCostTarget) {
      this.totalCostTarget.value = orderData.total_amount
    }
    
    this.updateTotalDisplay()
  }

  clearOrderData() {
    const targets = [
      'orderNumber', 'customerName', 'productName', 'carDetails',
      'productCost', 'taxAmount', 'shippingCost', 'totalCost'
    ]
    
    targets.forEach(targetName => {
      const target = this[`${targetName}Target`]
      if (target) target.value = ''
    })
    
    this.updateTotalDisplay()
  }

  // Action method for supplier cost input changes
  supplierCostChanged(event) {
    this.calculateProfit()
  }

  // Real-time profit calculation
  calculateProfit() {
    // Get customer total from the financial overview section
    let customerTotal = 0
    if (this.hasCustomerTotalTarget) {
      const totalText = this.customerTotalTarget.textContent.replace(/[$,\s]/g, '')
      customerTotal = parseFloat(totalText) || 0
    }
    
    const supplierCost = parseFloat(this.getTargetValue('supplierCost')) || 0
    const profit = customerTotal - supplierCost
    const profitMargin = customerTotal > 0 ? ((profit / customerTotal) * 100) : 0
    
    console.log('Calculating profit:', { customerTotal, supplierCost, profit, profitMargin })
    console.log('Applying styling for profit:', profit > 0 ? 'positive' : profit < 0 ? 'negative' : 'zero')
    
    // Update profit displays
    this.updateProfitDisplay(profit, profitMargin)
    this.updateSupplierCostDisplay(supplierCost)
    
    // Add visual feedback for profit/loss
    this.updateProfitStyling(profit)
  }

  updateProfitDisplay(profit, margin) {
    if (this.hasProfitDisplayTarget) {
      if (profit > 0) {
        this.profitDisplayTarget.textContent = `+${this.formatCurrency(profit)}`
      } else if (profit < 0) {
        this.profitDisplayTarget.textContent = this.formatCurrency(profit)
      } else {
        this.profitDisplayTarget.textContent = '$0.00'
      }
    }
    
    if (this.hasProfitMarginTarget) {
      this.profitMarginTarget.textContent = `${margin.toFixed(2)}%`
    }
  }

  updateSupplierCostDisplay(cost) {
    if (this.hasSupplierCostDisplayTarget) {
      this.supplierCostDisplayTarget.textContent = this.formatCurrency(cost)
    }
  }

  updateProfitStyling(profit) {
    // Style profit display
    if (this.hasProfitDisplayTarget) {
      const profitElement = this.profitDisplayTarget
      
      // Remove existing classes
      profitElement.classList.remove('profit-positive', 'profit-negative', 'profit-zero')
      
      // Add appropriate class
      if (profit > 0) {
        profitElement.classList.add('profit-positive')
      } else if (profit < 0) {
        profitElement.classList.add('profit-negative')
      } else {
        profitElement.classList.add('profit-zero')
      }
    }
    
    // Style profit margin display with same logic
    if (this.hasProfitMarginTarget) {
      const marginElement = this.profitMarginTarget
      
      // Remove existing classes
      marginElement.classList.remove('profit-positive', 'profit-negative', 'profit-zero')
      
      // Add appropriate class based on profit (not margin percentage)
      if (profit > 0) {
        marginElement.classList.add('profit-positive')
      } else if (profit < 0) {
        marginElement.classList.add('profit-negative')
      } else {
        marginElement.classList.add('profit-zero')
      }
    }
  }

  // Status management - show/hide tracking section and update timeline
  updateStatusFields(event) {
    const status = event.target.value
    
    if (['shipped', 'completed'].includes(status)) {
      this.showTrackingSection()
    } else {
      this.hideTrackingSection()
    }
    
    // Add status-specific styling
    this.updateStatusStyling(status)
    
    // Update timeline in real-time
    this.updateTimelineProgress(status)
    
    // Update status badge
    this.updateStatusBadge(status)
  }

  showTrackingSection() {
    if (this.hasTrackingSectionTarget) {
      this.trackingSectionTarget.style.display = 'block'
      this.trackingSectionTarget.style.opacity = '0'
      
      // Smooth show animation
      setTimeout(() => {
        this.trackingSectionTarget.style.opacity = '1'
      }, 10)
    }
  }

  hideTrackingSection() {
    if (this.hasTrackingSectionTarget) {
      this.trackingSectionTarget.style.opacity = '0'
      
      setTimeout(() => {
        this.trackingSectionTarget.style.display = 'none'
      }, 200)
    }
  }

  updateStatusStyling(status) {
    const statusSelect = this.element.querySelector('.status-select')
    if (!statusSelect) return
    
    // Remove existing status classes
    statusSelect.classList.remove('status-pending', 'status-processing', 'status-shipped', 'status-completed')
    
    // Add current status class
    statusSelect.classList.add(`status-${status}`)
  }

  // Supplier lookup functionality
  lookupSupplier() {
    this.showLookupModal('supplier')
    this.loadSuppliers()
  }

  showLookupModal(type) {
    const modal = document.getElementById(`${type}-lookup`)
    if (modal) {
      modal.classList.add('active')
      
      // Focus on search input
      setTimeout(() => {
        const searchInput = modal.querySelector('.search-input')
        if (searchInput) searchInput.focus()
      }, 100)
    }
  }

  closeLookupModal(event) {
    const type = event.params?.type || event.currentTarget.dataset.type
    const modal = document.getElementById(`${type}-lookup`)
    
    if (modal) {
      modal.classList.remove('active')
    }
  }

  loadSuppliers() {
    fetch('/dispatches/suppliers.json')
      .then(response => response.json())
      .then(suppliers => {
        this.populateSuppliersList(suppliers)
      })
      .catch(error => {
        console.error('Error loading suppliers:', error)
      })
  }

  populateSuppliersList(suppliers) {
    const container = document.getElementById('suppliers-list')
    if (!container) return
    
    container.innerHTML = suppliers.map(supplier => `
      <div class="lookup-item" onclick="selectSupplier('${supplier.name}')">
        <div class="supplier-name">${supplier.name}</div>
        <div class="supplier-info">${supplier.orders_count} orders</div>
      </div>
    `).join('')
  }

  // Form submission with enhanced feedback
  submitForm() {
    const form = this.formTarget
    if (!form) return
    
    // Add loading state
    this.setFormLoading(true)
    
    // Validate required fields
    if (!this.validateForm()) {
      this.setFormLoading(false)
      return
    }
    
    form.submit()
  }

  validateForm() {
    const requiredFields = [
      { target: 'supplierName', message: 'Supplier name is required' },
      { target: 'supplierCost', message: 'Supplier cost is required' }
    ]
    
    for (const field of requiredFields) {
      const target = this[`${field.target}Target`]
      if (target && !target.value.trim()) {
        this.showError(field.message)
        target.focus()
        return false
      }
    }
    
    return true
  }

  setFormLoading(loading) {
    const submitButtons = this.element.querySelectorAll('button[type="submit"]')
    
    submitButtons.forEach(button => {
      if (loading) {
        button.disabled = true
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...'
      } else {
        button.disabled = false
        button.innerHTML = button.dataset.originalText || 'Update Dispatch'
      }
    })
  }

  // Helper methods
  getTargetValue(targetName) {
    const target = this[`${targetName}Target`]
    return target ? target.value : ''
  }

  updateTotalDisplay() {
    const total = parseFloat(this.getTargetValue('totalCost')) || 0
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = this.formatCurrency(total)
    }
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
  }

  showError(message) {
    // Create toast notification
    const toast = document.createElement('div')
    toast.className = 'toast toast-error'
    toast.innerHTML = `
      <i class="fas fa-exclamation-triangle"></i>
      ${message}
    `
    
    document.body.appendChild(toast)
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    }, 5000)
  }

  showSuccess(message) {
    const toast = document.createElement('div')
    toast.className = 'toast toast-success'
    toast.innerHTML = `
      <i class="fas fa-check-circle"></i>
      ${message}
    `
    
    document.body.appendChild(toast)
    
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    }, 3000)
  }


  // Update timeline progress based on status
  updateTimelineProgress(status) {
    const timelineItems = document.querySelectorAll('.unified-timeline-item')
    const progressBar = document.querySelector('.unified-timeline-progress')
    
    if (!timelineItems.length || !progressBar) return
    
    // Reset all items
    timelineItems.forEach(item => {
      item.className = 'unified-timeline-item pending'
    })
    
    let progressWidth = 0
    
    // Update based on status
    switch(status) {
      case 'pending':
      case 'assigned':
        timelineItems[0].className = 'unified-timeline-item active'
        progressWidth = 0
        break
      case 'processing':
        timelineItems[0].className = 'unified-timeline-item completed'
        timelineItems[1].className = 'unified-timeline-item active'
        // Add spinning animation to processing
        const processingIcon = timelineItems[1].querySelector('i')
        if (processingIcon) {
          processingIcon.className = 'fas fa-cog fa-spin'
        }
        progressWidth = 33
        break
      case 'shipped':
        timelineItems[0].className = 'unified-timeline-item completed'
        timelineItems[1].className = 'unified-timeline-item completed'
        timelineItems[2].className = 'unified-timeline-item active'
        progressWidth = 66
        break
      case 'completed':
        timelineItems[0].className = 'unified-timeline-item completed'
        timelineItems[1].className = 'unified-timeline-item completed'
        timelineItems[2].className = 'unified-timeline-item completed'
        timelineItems[3].className = 'unified-timeline-item active'
        progressWidth = 100
        break
      case 'cancelled':
        timelineItems.forEach(item => {
          item.className = 'unified-timeline-item cancelled'
        })
        progressWidth = 0
        break
    }
    
    // Update progress bar with smooth animation
    progressBar.style.width = progressWidth + '%'
  }

  // Update status badge in header
  updateStatusBadge(status) {
    const statusBadge = document.querySelector('.current-status-badge')
    if (statusBadge) {
      statusBadge.className = `current-status-badge status-${status}`
      statusBadge.textContent = status.charAt(0).toUpperCase() + status.slice(1).replace('_', ' ')
    }
  }

  // Enhanced status styling with animations
  updateStatusStyling(status) {
    const statusSelect = this.element.querySelector('.status-select')
    
    if (statusSelect) {
      // Remove existing status classes
      statusSelect.classList.remove(
        'status-pending', 'status-assigned', 'status-processing', 
        'status-shipped', 'status-completed', 'status-cancelled'
      )
      
      // Add current status class with animation
      statusSelect.classList.add(`status-${status}`)
      
      // Add a subtle animation
      statusSelect.style.transform = 'scale(1.02)'
      setTimeout(() => {
        statusSelect.style.transform = 'scale(1)'
      }, 200)
    }
  }

  // Validation for status transitions
  validateStatusTransition(currentStatus, newStatus) {
    const validTransitions = {
      'pending': ['assigned', 'processing', 'cancelled'],
      'assigned': ['processing', 'cancelled'],
      'processing': ['shipped', 'cancelled'],
      'shipped': ['completed', 'cancelled'],
      'completed': [], // No transitions from completed
      'cancelled': [] // No transitions from cancelled
    }
    
    return validTransitions[currentStatus]?.includes(newStatus) || false
  }

  // Auto-save functionality for status changes
  autoSaveStatus() {
    if (this.hasFormTarget) {
      const formData = new FormData(this.formTarget)
      
      fetch(this.formTarget.action, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.showSuccess('Changes saved automatically')
        }
      })
      .catch(error => {
        console.error('Auto-save failed:', error)
      })
    }
  }
}

// Global function for supplier selection
window.selectSupplier = function(supplierName) {
  const supplierInput = document.querySelector('[data-dispatch-form-target="supplierName"]')
  if (supplierInput) {
    supplierInput.value = supplierName
    supplierInput.dispatchEvent(new Event('input', { bubbles: true }))
  }
  
  // Close modal
  const modal = document.getElementById('supplier-lookup')
  if (modal) {
    modal.classList.remove('active')
  }
}