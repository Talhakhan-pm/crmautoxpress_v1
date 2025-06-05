import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pagination"
export default class extends Controller {
  static targets = ["link", "info"]
  static values = { currentPage: Number, totalPages: Number, totalCount: Number }

  connect() {
    this.addLoadingStates()
    this.addKeyboardNavigation()
    this.updatePageInfo()
  }

  addLoadingStates() {
    // Add loading states to pagination links
    this.linkTargets.forEach(link => {
      link.addEventListener('click', this.showLoadingState.bind(this))
    })
  }

  addKeyboardNavigation() {
    // Enable keyboard navigation for pagination
    document.addEventListener('keydown', this.handleKeyboardNavigation.bind(this))
  }

  showLoadingState(event) {
    const link = event.currentTarget
    link.classList.add('loading')
    
    // Remove loading state after a short delay (will be removed when new content loads)
    setTimeout(() => {
      link.classList.remove('loading')
    }, 2000)
  }

  handleKeyboardNavigation(event) {
    // Only handle if no input is focused
    if (document.activeElement.tagName === 'INPUT' || 
        document.activeElement.tagName === 'TEXTAREA' ||
        document.activeElement.tagName === 'SELECT') {
      return
    }

    switch(event.key) {
      case 'ArrowLeft':
        event.preventDefault()
        this.navigateToPrevious()
        break
      case 'ArrowRight':
        event.preventDefault()
        this.navigateToNext()
        break
      case 'Home':
        event.preventDefault()
        this.navigateToFirst()
        break
      case 'End':
        event.preventDefault()
        this.navigateToLast()
        break
    }
  }

  navigateToPrevious() {
    const prevLink = this.element.querySelector('.page-item.prev:not(.disabled) .page-link')
    if (prevLink) {
      this.showLoadingState({ currentTarget: prevLink })
      prevLink.click()
    }
  }

  navigateToNext() {
    const nextLink = this.element.querySelector('.page-item.next:not(.disabled) .page-link')
    if (nextLink) {
      this.showLoadingState({ currentTarget: nextLink })
      nextLink.click()
    }
  }

  navigateToFirst() {
    const firstLink = this.element.querySelector('.page-item.first:not(.disabled) .page-link')
    if (firstLink) {
      this.showLoadingState({ currentTarget: firstLink })
      firstLink.click()
    }
  }

  navigateToLast() {
    const lastLink = this.element.querySelector('.page-item.last:not(.disabled) .page-link')
    if (lastLink) {
      this.showLoadingState({ currentTarget: lastLink })
      lastLink.click()
    }
  }

  updatePageInfo() {
    if (this.hasInfoTarget && this.hasCurrentPageValue && this.hasTotalPagesValue) {
      const startItem = ((this.currentPageValue - 1) * 25) + 1
      const endItem = Math.min(this.currentPageValue * 25, this.totalCountValue)
      
      this.infoTarget.innerHTML = `
        <div class="page-details">
          Showing <span class="current-range">${startItem}-${endItem}</span> 
          of <span class="total-count">${this.totalCountValue.toLocaleString()}</span> orders
          (Page <span class="current-page">${this.currentPageValue}</span> of ${this.totalPagesValue})
        </div>
      `
    }
  }

  // Stimulus value change callbacks
  currentPageValueChanged() {
    this.updatePageInfo()
  }

  totalPagesValueChanged() {
    this.updatePageInfo()
  }

  totalCountValueChanged() {
    this.updatePageInfo()
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.handleKeyboardNavigation.bind(this))
  }
}