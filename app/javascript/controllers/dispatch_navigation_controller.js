import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dispatchUrl: String }

  navigateToDispatch(event) {
    event.preventDefault()
    const dispatchUrl = this.element.dataset.dispatchUrl || this.dispatchUrlValue
    
    if (dispatchUrl) {
      this.openDispatchModal(dispatchUrl)
    }
  }

  async openDispatchModal(dispatchUrl) {
    try {
      const modal = document.getElementById('dispatch-modal')
      const modalBody = document.getElementById('modal-body')
      
      if (!modal || !modalBody) {
        return
      }

      // Show loading state
      modalBody.innerHTML = '<div class="loading-spinner"><i class="fas fa-spinner fa-spin"></i> Loading...</div>'
      
      // Open the modal
      modal.classList.add('active')
      document.body.style.overflow = 'hidden'
      
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
      } else {
        modalBody.innerHTML = '<div class="error-message">Failed to load dispatch details</div>'
      }
    } catch (error) {
      const modalBody = document.getElementById('modal-body')
      if (modalBody) {
        modalBody.innerHTML = '<div class="error-message">Error loading dispatch details</div>'
      }
    }
  }
}