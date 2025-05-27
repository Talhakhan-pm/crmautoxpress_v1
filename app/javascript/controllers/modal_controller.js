import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]
  static values = { theme: String, closeUrl: String }

  connect() {
    // Close modal on escape key
    this.boundEscapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundEscapeHandler)
    
    // Close modal when clicking outside
    this.boundClickOutsideHandler = this.handleClickOutside.bind(this)
    this.element.addEventListener("click", this.boundClickOutsideHandler)

    // Apply theme if specified
    if (this.hasThemeValue) {
      this.element.classList.add(`theme-${this.themeValue}`)
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundEscapeHandler)
    this.element.removeEventListener("click", this.boundClickOutsideHandler)
  }

  open() {
    this.element.classList.add("active")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.element.classList.remove("active")
    document.body.style.overflow = ""
  }

  closeModal(event) {
    event.preventDefault()
    this.close()
    
    // Check if we're inside a turbo frame
    const frame = this.element.closest('turbo-frame')
    
    if (frame) {
      // Stay within the frame - use frame navigation
      const targetUrl = this.hasCloseUrlValue ? this.closeUrlValue : this.getContextualUrl()
      frame.src = targetUrl
    } else {
      // Only use full navigation if not in a frame
      const targetUrl = this.hasCloseUrlValue ? this.closeUrlValue : this.getContextualUrl()
      window.Turbo.visit(targetUrl)
    }
  }

  // Get contextual URL based on current location
  getContextualUrl() {
    const currentPath = window.location.pathname
    
    if (currentPath.includes('/dispatches')) {
      return '/dispatches'
    } else if (currentPath.includes('/orders')) {
      return '/orders'
    } else if (currentPath.includes('/callbacks')) {
      return '/callbacks'
    } else if (currentPath.includes('/customers')) {
      return '/customers'
    } else if (currentPath.includes('/refunds')) {
      return '/refunds'
    }
    
    return '/dashboard' // Safe fallback
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.element.classList.contains("active")) {
      this.closeModal(event)
    }
  }

  handleClickOutside(event) {
    // Handle both unified modal and old modal systems
    const unifiedModalContent = this.element.querySelector('.unified-modal-content')
    const oldModalContent = this.element.querySelector('.modal-content')
    const modalContent = unifiedModalContent || oldModalContent
    
    if (event.target === this.element || (modalContent && !modalContent.contains(event.target))) {
      this.closeModal(event)
    }
  }

  // Timeline specific methods
  updateTimeline(status) {
    const timelineItems = this.element.querySelectorAll('.timeline-item')
    const progressBar = this.element.querySelector('.timeline-progress')
    
    if (!timelineItems.length || !progressBar) return
    
    // Reset all items
    timelineItems.forEach(item => {
      item.className = 'timeline-item pending'
    })
    
    let progressWidth = 0
    
    // Update based on status
    switch(status) {
      case 'pending':
        timelineItems[0].className = 'timeline-item active'
        progressWidth = 0
        break
      case 'processing':
        timelineItems[0].className = 'timeline-item completed'
        timelineItems[1].className = 'timeline-item active'
        // Add spinning animation to processing
        const processingIcon = timelineItems[1].querySelector('i')
        if (processingIcon) {
          processingIcon.className = 'fas fa-cog fa-spin'
        }
        progressWidth = 33
        break
      case 'shipped':
        timelineItems[0].className = 'timeline-item completed'
        timelineItems[1].className = 'timeline-item completed'
        timelineItems[2].className = 'timeline-item active'
        progressWidth = 66
        break
      case 'completed':
        timelineItems[0].className = 'timeline-item completed'
        timelineItems[1].className = 'timeline-item completed'
        timelineItems[2].className = 'timeline-item completed'
        timelineItems[3].className = 'timeline-item active'
        progressWidth = 100
        break
    }
    
    // Update progress bar with smooth animation
    progressBar.style.width = progressWidth + '%'
  }

  // Method to update timeline dates
  updateTimelineDates(dates) {
    const timelineItems = this.element.querySelectorAll('.timeline-item')
    
    if (dates.pending && timelineItems[0]) {
      const dateEl = timelineItems[0].querySelector('.timeline-date')
      if (dateEl) dateEl.textContent = dates.pending
    }
    
    if (dates.processing && timelineItems[1]) {
      const dateEl = timelineItems[1].querySelector('.timeline-date')
      if (dateEl) dateEl.textContent = dates.processing
    }
    
    if (dates.shipped && timelineItems[2]) {
      const dateEl = timelineItems[2].querySelector('.timeline-date')
      if (dateEl) dateEl.textContent = dates.shipped
    }
    
    if (dates.completed && timelineItems[3]) {
      const dateEl = timelineItems[3].querySelector('.timeline-date')
      if (dateEl) dateEl.textContent = dates.completed
    }
  }
}