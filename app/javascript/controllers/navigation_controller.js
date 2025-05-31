import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  setActive(event) {
    event.preventDefault()
    
    const clickedItem = event.currentTarget
    const href = clickedItem.getAttribute("href")
    
    // Update active state immediately
    this.clearAllActive()
    clickedItem.classList.add("active")
    
    // Update browser URL manually
    window.history.pushState({}, '', href)
    
    // Use Turbo to visit the page but target the frame
    Turbo.visit(href, { frame: "main_content" })
  }

  clearAllActive() {
    const navItems = this.element.querySelectorAll('.nav-item')
    navItems.forEach(item => item.classList.remove('active'))
  }
}