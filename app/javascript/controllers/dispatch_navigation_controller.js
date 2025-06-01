import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dispatchUrl: String }

  connect() {
    console.log("Dispatch navigation controller connected")
  }

  navigateToDispatch(event) {
    event.preventDefault()
    const dispatchUrl = this.element.dataset.dispatchUrl || this.dispatchUrlValue
    console.log("Dispatch card clicked, opening modal for:", dispatchUrl)
    
    if (dispatchUrl) {
      this.openDispatchModal(dispatchUrl)
    } else {
      console.error("No dispatch URL found")
    }
  }

  async openDispatchModal(dispatchUrl) {
    try {
      // Find the modal
      const modal = document.getElementById('dispatch-modal')
      const modalBody = document.getElementById('modal-body')
      
      if (!modal || !modalBody) {
        console.error('Dispatch modal not found - modal:', !!modal, 'modalBody:', !!modalBody)
        return
      }

      // Show loading state
      modalBody.innerHTML = '<div class="loading-spinner"><i class="fas fa-spinner fa-spin"></i> Loading...</div>'
      
      // Use the modal controller's open method
      modal.classList.add('active')
      document.body.style.overflow = 'hidden'
      console.log('Modal opened with active class')
      
      // Fetch dispatch details
      const response = await fetch(dispatchUrl, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const html = await response.text()
        modalBody.innerHTML = html
        console.log('Modal content loaded successfully')
      } else {
        modalBody.innerHTML = '<div class="error-message">Failed to load dispatch details</div>'
        console.error('Failed to fetch dispatch details:', response.status)
      }
    } catch (error) {
      console.error('Error loading dispatch modal:', error)
      const modalBody = document.getElementById('modal-body')
      if (modalBody) {
        modalBody.innerHTML = '<div class="error-message">Error loading dispatch details</div>'
      }
    }
  }
}