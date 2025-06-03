import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", "form", "phoneNumber", "submitBtn", "followupSection", 
    "followupDateInput", "notesCard", "notesContent"
  ]
  
  static values = { 
    closeUrl: String 
  }

  connect() {
    console.log('Callback form controller connected')
    this.setupPhoneFormatting()
    this.setupFormValidation()
    this.initializeQuickFeatures()
  }

  disconnect() {
    // Cleanup event listeners if needed
  }

  // Phone number formatting
  setupPhoneFormatting() {
    if (this.hasPhoneNumberTarget) {
      this.phoneNumberTarget.addEventListener('input', (e) => {
        this.formatPhoneNumber(e)
      })
    }
  }

  formatPhoneNumber(event) {
    let value = event.target.value.replace(/\D/g, '')
    if (value.length >= 6) {
      value = `(${value.slice(0,3)}) ${value.slice(3,6)}-${value.slice(6,10)}`
    } else if (value.length >= 3) {
      value = `(${value.slice(0,3)}) ${value.slice(3)}`
    }
    event.target.value = value
  }

  // Form validation
  setupFormValidation() {
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', (e) => {
        this.handleSubmit(e)
      })
    }
  }

  handleSubmit(event) {
    // Add loading state to submit button
    if (this.hasSubmitBtnTarget) {
      this.setSubmitLoading(true)
    }

    // Store original button state for error handling
    this.originalSubmitState = {
      button: this.submitBtnTarget,
      text: this.submitBtnTarget.innerHTML
    }
  }

  // Handle successful form submission
  handleSuccess(event) {
    console.log('Callback saved successfully!')
    this.setSubmitLoading(false)
    this.showNotification('Callback saved successfully!', 'success')
    
    // Close modal after short delay to show success message
    setTimeout(() => {
      this.closeModal()
    }, 1500)
  }

  // Handle form submission errors
  handleError(event) {
    console.error('Callback save failed:', event.detail)
    this.setSubmitLoading(false)
    this.showNotification('Failed to save callback. Please try again.', 'error')
  }

  // Set loading state on submit button
  setSubmitLoading(loading) {
    if (!this.hasSubmitBtnTarget) return

    if (loading) {
      this.submitBtnTarget.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...'
      this.submitBtnTarget.disabled = true
    } else {
      this.submitBtnTarget.innerHTML = this.originalSubmitState?.text || 'Save Callback'
      this.submitBtnTarget.disabled = false
    }
  }

  // Close modal and navigate appropriately
  closeModal() {
    // Check if we're inside a turbo frame
    const frame = this.element.closest('turbo-frame')
    
    // Determine target URL
    let targetUrl = this.hasCloseUrlValue ? this.closeUrlValue : '/callbacks'
    
    if (frame) {
      // Stay within the frame
      frame.src = targetUrl
      // Update browser URL for consistency
      window.history.replaceState(null, '', targetUrl)
    } else {
      // Full navigation if not in frame
      window.Turbo.visit(targetUrl)
    }
  }

  // Tab switching functionality for detail views
  switchTab(event) {
    const clickedTab = event.currentTarget
    const tabIndex = Array.from(clickedTab.parentNode.children).indexOf(clickedTab)
    
    // Remove active class from all tabs
    this.element.querySelectorAll('.tab-item').forEach(tab => {
      tab.classList.remove('active')
    })
    
    // Hide all tab content
    this.element.querySelectorAll('.tab-content').forEach(content => {
      content.style.display = 'none'
    })
    
    // Activate clicked tab
    clickedTab.classList.add('active')
    
    // Show corresponding content
    const tabContents = this.element.querySelectorAll('.tab-content')
    if (tabContents[tabIndex]) {
      tabContents[tabIndex].style.display = 'block'
    }
  }

  // Activity filter functionality
  filterActivities(event) {
    const filter = event.currentTarget.dataset.filter
    
    // Update filter buttons
    this.element.querySelectorAll('.filter-chip').forEach(chip => {
      chip.classList.remove('active')
    })
    event.currentTarget.classList.add('active')
    
    // Apply filter
    this.applyActivityFilter(filter)
  }

  applyActivityFilter(filter) {
    const activityItems = this.element.querySelectorAll('.timeline-item, .activity-item')
    
    activityItems.forEach(item => {
      const shouldShow = filter === 'all' || item.dataset.action === filter
      item.style.display = shouldShow ? 'block' : 'none'
    })
  }

  // Search functionality for callbacks
  searchCallbacks(event) {
    const query = event.target.value.toLowerCase().trim()
    const callbackRows = document.querySelectorAll('#callbacks tr[data-status]')
    let visibleCount = 0
    
    callbackRows.forEach(row => {
      const text = row.textContent.toLowerCase()
      const matchesSearch = !query || text.includes(query)
      
      // Also check current status filter
      const activeFilter = document.querySelector('.filter-btn.active')
      const statusFilter = activeFilter ? activeFilter.dataset.status : 'all'
      const matchesStatus = statusFilter === 'all' || row.dataset.status === statusFilter
      
      const shouldShow = matchesSearch && matchesStatus
      row.style.display = shouldShow ? '' : 'none'
      
      if (shouldShow) visibleCount++
    })
    
    // Update pagination info
    this.updatePaginationInfo(visibleCount, callbackRows.length)
  }

  // Status filter functionality
  filterByStatus(event) {
    const status = event.currentTarget.dataset.status
    
    // Update filter buttons
    const filterGroup = event.currentTarget.closest('.filter-group')
    if (filterGroup) {
      filterGroup.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active')
      })
      event.currentTarget.classList.add('active')
    }
    
    // Apply status filter
    this.applyStatusFilter(status)
  }

  applyStatusFilter(status) {
    const callbackRows = document.querySelectorAll('#callbacks tr[data-status]')
    let visibleCount = 0
    
    callbackRows.forEach(row => {
      const matchesStatus = status === 'all' || row.dataset.status === status
      
      // Also check search query
      const searchInput = document.querySelector('.search-box input')
      const query = searchInput ? searchInput.value.toLowerCase().trim() : ''
      const matchesSearch = !query || row.textContent.toLowerCase().includes(query)
      
      const shouldShow = matchesStatus && matchesSearch
      row.style.display = shouldShow ? '' : 'none'
      
      if (shouldShow) visibleCount++
    })
    
    this.updatePaginationInfo(visibleCount, callbackRows.length)
  }

  updatePaginationInfo(visible, total) {
    const paginationInfo = document.querySelector('.pagination-info')
    if (paginationInfo) {
      paginationInfo.textContent = `Showing ${visible} of ${total} results`
    }
  }

  // Show notification to user
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.className = `notification notification-${type}`
    notification.innerHTML = `
      <div class="notification-content">
        <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
        <span>${message}</span>
      </div>
    `
    
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: ${type === 'success' ? '#10b981' : '#ef4444'};
      color: white;
      padding: 12px 16px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      z-index: 10000;
      display: flex;
      align-items: center;
      gap: 8px;
      font-weight: 500;
      transform: translateX(100%);
      transition: transform 0.3s ease;
    `
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
    }, 100)
    
    // Remove after delay
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification)
        }
      }, 300)
    }, 3000)
  }

  // === NEW QUICK FORM FEATURES ===

  // Initialize quick form features
  initializeQuickFeatures() {
    this.setupDateButtons()
    this.setupNotesToggle()
  }

  // Enhanced phone formatting for quick form
  formatPhone(event) {
    this.formatPhoneNumber(event)
  }

  // Simple field validation (no visual styling)
  validateField(event) {
    // Just basic validation, no special styling
    return event.target.checkValidity()
  }

  // Set follow-up date from quick buttons
  setFollowupDate(event) {
    event.preventDefault()
    const days = parseInt(event.currentTarget.dataset.days)
    const today = new Date()
    const followupDate = new Date(today.getTime() + (days * 24 * 60 * 60 * 1000))
    
    if (this.hasFollowupDateInputTarget) {
      this.followupDateInputTarget.value = followupDate.toISOString().split('T')[0]
      this.followupDateInputTarget.classList.remove('show')
    }
    
    // Update button states
    this.updateDateButtonStates(event.currentTarget)
  }

  // Show custom date picker
  showCustomDate(event) {
    event.preventDefault()
    
    if (this.hasFollowupDateInputTarget) {
      this.followupDateInputTarget.classList.add('show')
      this.followupDateInputTarget.focus()
    }
    
    this.updateDateButtonStates(event.currentTarget)
  }

  // Update date button visual states
  updateDateButtonStates(activeButton) {
    const allButtons = this.element.querySelectorAll('.quick-date-btn')
    allButtons.forEach(btn => btn.classList.remove('active'))
    activeButton.classList.add('active')
  }

  // Update status and show/hide follow-up section
  updateStatus(event) {
    const status = event.target.value
    const followupSection = this.hasFollowupSectionTarget ? this.followupSectionTarget : null
    
    if (followupSection) {
      // Show follow-up date for statuses that typically need follow-up
      const needsFollowup = ['pending', 'follow_up', 'payment_link'].includes(status)
      followupSection.style.display = needsFollowup ? 'block' : 'none'
    }
  }

  // Toggle notes section
  toggleNotes(event) {
    event.preventDefault()
    
    if (this.hasNotesCardTarget) {
      this.notesCardTarget.classList.toggle('expanded')
    }
  }

  // Setup date button interactions
  setupDateButtons() {
    // Set default active button (Tomorrow)
    const tomorrowBtn = this.element.querySelector('[data-days="1"]')
    if (tomorrowBtn) {
      this.updateDateButtonStates(tomorrowBtn)
    }
  }

  // Setup notes toggle functionality
  setupNotesToggle() {
    // Notes section starts collapsed
    if (this.hasNotesCardTarget) {
      this.notesCardTarget.classList.remove('expanded')
    }
  }


  // Auto-save draft functionality (optional enhancement)
  saveDraft() {
    const formData = new FormData(this.formTarget)
    const draftData = {}
    
    for (let [key, value] of formData.entries()) {
      draftData[key] = value
    }
    
    localStorage.setItem('callback_draft', JSON.stringify(draftData))
    
    // Show subtle indicator
    this.showNotification('Draft saved', 'info')
  }

  // Load draft data (optional enhancement)
  loadDraft() {
    const draftData = localStorage.getItem('callback_draft')
    
    if (draftData) {
      try {
        const data = JSON.parse(draftData)
        
        Object.keys(data).forEach(key => {
          const field = this.formTarget.querySelector(`[name="${key}"]`)
          if (field && !field.value) {
            field.value = data[key]
          }
        })
        
        // Clear draft after loading
        localStorage.removeItem('callback_draft')
      } catch (e) {
        console.warn('Failed to load draft data:', e)
      }
    }
  }
}