import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput"]

  connect() {
    console.log("Dispatch filter controller connected")
  }

  // Auto-submit search with debounce
  search() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.submitForm()
    }, 500)
  }

  submitForm() {
    const form = this.element.closest('form')
    if (form) {
      // Submit form with turbo frame targeting
      const formData = new FormData(form)
      const params = new URLSearchParams(formData)
      const url = `${form.action}?${params.toString()}`
      
      // Navigate with turbo frame
      window.Turbo.visit(url, { frame: "main_content" })
    }
  }
}