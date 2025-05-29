import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="order-timeline"
export default class extends Controller {
  static targets = ["panel", "toggleButton"]
  static values = { expanded: Boolean }

  connect() {
    console.log("📊 Order Timeline Controller connected")
  }

  toggleTimeline(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const panel = this.panelTarget
    const button = this.toggleButtonTarget
    const icon = button.querySelector('i')
    
    if (this.expandedValue) {
      // Close timeline
      panel.style.display = "none"
      this.expandedValue = false
      
      // Update button appearance
      button.classList.remove('timeline-expanded')
      icon.className = "fas fa-history"
      button.title = "View Timeline"
      
      console.log("📊 Timeline panel closed")
    } else {
      // Open timeline
      panel.style.display = "block"
      this.expandedValue = true
      
      // Update button appearance
      button.classList.add('timeline-expanded')
      icon.className = "fas fa-times"
      button.title = "Close Timeline"
      
      // Scroll timeline into view if needed
      setTimeout(() => {
        panel.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
      }, 100)
      
      console.log("📊 Timeline panel opened")
    }
  }

  // Close timeline when clicking outside (optional)
  clickOutside(event) {
    if (this.expandedValue && !this.element.contains(event.target)) {
      this.closeTimeline()
    }
  }

  closeTimeline() {
    if (this.expandedValue) {
      this.toggleTimeline({ preventDefault: () => {}, stopPropagation: () => {} })
    }
  }

  // Handle timeline item clicks for highlighting
  highlightItem(event) {
    const item = event.currentTarget
    
    // Remove previous highlights
    this.element.querySelectorAll('.timeline-item-highlight').forEach(el => {
      el.classList.remove('timeline-item-highlight')
    })
    
    // Add highlight to clicked item
    item.classList.add('timeline-item-highlight')
    
    // Auto-remove highlight after 3 seconds
    setTimeout(() => {
      item.classList.remove('timeline-item-highlight')
    }, 3000)
  }

  // Filter timeline by type
  filterByType(event) {
    const filterType = event.target.dataset.filterType
    const timelineItems = this.element.querySelectorAll('.timeline-flow-item')
    
    timelineItems.forEach(item => {
      const itemType = item.dataset.timelineType
      
      if (filterType === 'all' || itemType === filterType) {
        item.style.display = 'flex'
      } else {
        item.style.display = 'none'
      }
    })
    
    // Update filter button states
    this.updateFilterButtons(filterType)
  }

  updateFilterButtons(activeType) {
    const filterButtons = this.element.querySelectorAll('.timeline-filter-btn')
    
    filterButtons.forEach(button => {
      if (button.dataset.filterType === activeType) {
        button.classList.add('active-filter')
      } else {
        button.classList.remove('active-filter')
      }
    })
  }

  disconnect() {
    console.log("📊 Order Timeline Controller disconnected")
  }
}