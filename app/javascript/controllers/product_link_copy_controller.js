import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="product-link-copy"
export default class extends Controller {
  static targets = ["toast", "icon"]
  static values = { url: String }

  async copyLink(event) {
    event.preventDefault()
    event.stopPropagation()

    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.showSuccessToast()
      this.updateIcon()
    } catch (err) {
      // Fallback for older browsers
      this.fallbackCopyTextToClipboard(this.urlValue)
    }
  }

  showSuccessToast() {
    this.toastTarget.classList.add("show")
    
    setTimeout(() => {
      this.toastTarget.classList.remove("show")
    }, 2000)
  }

  updateIcon() {
    const copyBtn = this.iconTarget.closest('.copy-btn')
    const originalIcon = this.iconTarget.className
    
    // Change to checkmark
    this.iconTarget.className = "fas fa-check"
    copyBtn.classList.add("copied")
    
    // Revert after 2 seconds
    setTimeout(() => {
      this.iconTarget.className = originalIcon
      copyBtn.classList.remove("copied")
    }, 2000)
  }

  fallbackCopyTextToClipboard(text) {
    const textArea = document.createElement("textarea")
    textArea.value = text
    
    // Avoid scrolling to bottom
    textArea.style.top = "0"
    textArea.style.left = "0"
    textArea.style.position = "fixed"
    
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      const successful = document.execCommand('copy')
      if (successful) {
        this.showSuccessToast()
        this.updateIcon()
      }
    } catch (err) {
      console.error('Fallback: Oops, unable to copy', err)
    }
    
    document.body.removeChild(textArea)
  }
}