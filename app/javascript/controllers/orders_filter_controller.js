import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "form", "ordersFrame"]
  static values = { url: String }

  connect() {
    console.log("Orders filter controller connected")
  }

  // Auto-submit search with debounce
  search() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.submitForm()
    }, 500)
  }

  // Submit form on dropdown change
  change() {
    this.submitForm()
  }

  // Submit the form and update the turbo frame
  submitForm() {
    const formData = new FormData(this.formTarget)
    const params = new URLSearchParams(formData)
    const url = `${this.urlValue}?${params.toString()}`
    
    // Update the turbo frame
    const turboFrame = this.ordersFrameTarget.querySelector('turbo-frame')
    if (turboFrame) {
      turboFrame.src = url
    }
  }

  // Handle view toggle
  setView(event) {
    const view = event.params.view
    const url = new URL(window.location)
    
    if (view === 'table') {
      url.searchParams.set('view', 'table')
    } else {
      url.searchParams.delete('view')
    }
    
    // Update frame with current filters + view
    const turboFrame = this.ordersFrameTarget.querySelector('turbo-frame')
    if (turboFrame) {
      turboFrame.src = url.toString()
    }
    
    // Update active state
    document.querySelectorAll('.view-btn').forEach(btn => btn.classList.remove('active'))
    event.target.classList.add('active')
  }

  // Clear all filters
  clearFilters() {
    const turboFrame = this.ordersFrameTarget.querySelector('turbo-frame')
    if (turboFrame) {
      turboFrame.src = this.urlValue
    }
    this.formTarget.reset()
  }

  // Show advanced filters modal
  showAdvancedFilters() {
    document.getElementById('advanced-filters').classList.add('active')
    document.body.style.overflow = 'hidden'
  }

  // Hide advanced filters modal
  hideAdvancedFilters() {
    document.getElementById('advanced-filters').classList.remove('active')
    document.body.style.overflow = 'auto'
  }

  // Navigate to order using turbo frames
  navigateToOrder(event) {
    event.preventDefault()
    const orderUrl = event.currentTarget.dataset.orderUrl
    const turboFrame = event.currentTarget.dataset.turboFrame
    
    if (orderUrl && turboFrame) {
      window.Turbo.visit(orderUrl, { frame: turboFrame })
    }
  }

  // Toggle return dropdown for specific order
  toggleReturnDropdown(event) {
    event.stopPropagation()
    
    const button = event.currentTarget
    const orderId = button.dataset.orderId
    const targetName = `returnDropdown${orderId}`
    
    // Find the dropdown target for this specific order
    const dropdown = this.element.querySelector(`[data-orders-filter-target="${targetName}"]`)
    
    if (!dropdown) return
    
    // Hide all other open dropdowns first
    this.element.querySelectorAll('[data-orders-filter-target^="returnDropdown"]').forEach(otherDropdown => {
      if (otherDropdown !== dropdown) {
        otherDropdown.style.display = 'none'
        // Remove active state from other buttons
        const otherButton = otherDropdown.closest('.action-dropdown')?.querySelector('.dropdown-toggle')
        if (otherButton) {
          otherButton.classList.remove('active')
        }
      }
    })
    
    // Toggle the current dropdown
    const isVisible = dropdown.style.display !== 'none'
    dropdown.style.display = isVisible ? 'none' : 'block'
    
    // Toggle active state on button
    if (isVisible) {
      button.classList.remove('active')
    } else {
      button.classList.add('active')
    }
    
    // Close dropdown when clicking outside
    if (!isVisible) {
      const closeOnOutsideClick = (e) => {
        if (!dropdown.contains(e.target) && !button.contains(e.target)) {
          dropdown.style.display = 'none'
          button.classList.remove('active')
          document.removeEventListener('click', closeOnOutsideClick)
        }
      }
      
      // Add listener on next tick to avoid immediate closing
      setTimeout(() => {
        document.addEventListener('click', closeOnOutsideClick)
      }, 10)
    }
  }
}