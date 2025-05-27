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
}