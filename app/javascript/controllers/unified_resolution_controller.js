import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "notes", "stage", "hub", "conversation", "messageInput", "quickActions", "progressBar", "statusIndicator"]
  static values = { refundId: Number, currentStage: String, userId: Number }

  connect() {
    console.log("Unified resolution controller connected")
    this.initializeCommunicationHub()
    this.setupRealTimeUpdates()
  }

  initializeCommunicationHub() {
    if (this.hasHubTarget) {
      this.loadConversationHistory()
      this.updateProgressBar()
      this.setupQuickActions()
    }
  }

  toggleHub(event) {
    event.preventDefault()
    const hub = this.hubTarget
    const isVisible = hub.classList.contains("show")
    
    if (isVisible) {
      this.hideHub()
    } else {
      this.showHub()
    }
  }

  showHub() {
    const hub = this.hubTarget
    hub.classList.add("show")
    hub.classList.remove("d-none")
    
    // Focus message input when opening
    if (this.hasMessageInputTarget) {
      setTimeout(() => this.messageInputTarget.focus(), 100)
    }
    
    // Mark as viewed
    this.markAsViewed()
  }

  hideHub() {
    const hub = this.hubTarget
    hub.classList.remove("show")
    hub.classList.add("d-none")
  }

  sendMessage(event) {
    event.preventDefault()
    const form = event.target
    const message = this.messageInputTarget.value.trim()
    
    if (!message) return
    
    // Add typing indicator
    this.showTypingIndicator()
    
    // Clear input immediately for better UX
    this.messageInputTarget.value = ""
    
    // Send message via fetch
    const formData = new FormData(form)
    formData.append('message', message)
    formData.append('message_type', this.getCurrentMessageType())
    
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    }).then(() => {
      this.hideTypingIndicator()
      this.scrollToBottom()
    })
  }

  executeQuickAction(event) {
    event.preventDefault()
    const button = event.currentTarget
    const action = button.dataset.action
    const actionData = button.dataset.actionData
    
    // Show confirmation for critical actions
    if (this.isCriticalAction(action)) {
      if (!confirm(`Are you sure you want to ${action.replace('_', ' ')}?`)) {
        return
      }
    }
    
    this.performAction(action, actionData)
  }

  performAction(action, data) {
    const url = `/resolution/${this.refundIdValue}/${action}`
    const formData = new FormData()
    
    if (data) {
      try {
        const parsedData = JSON.parse(data)
        Object.entries(parsedData).forEach(([key, value]) => {
          formData.append(key, value)
        })
      } catch {
        formData.append('action_data', data)
      }
    }
    
    // Show loading state
    this.showActionLoading(action)
    
    fetch(url, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    }).then(() => {
      this.hideActionLoading()
      this.updateProgressBar()
    })
  }

  updateProgressBar() {
    if (!this.hasProgressBarTarget) return
    
    const stages = ['pending_customer_clarification', 'pending_dispatch_decision', 'pending_customer_approval', 'resolution_completed']
    const currentIndex = stages.indexOf(this.currentStageValue)
    const progress = ((currentIndex + 1) / stages.length) * 100
    
    this.progressBarTarget.style.width = `${progress}%`
    this.progressBarTarget.setAttribute('aria-valuenow', progress)
  }

  setupQuickActions() {
    if (!this.hasQuickActionsTarget) return
    
    const actions = this.getContextualActions()
    this.renderQuickActions(actions)
  }

  getContextualActions() {
    switch (this.currentStageValue) {
      case 'pending_customer_clarification':
        return [
          { label: 'Mark as Clarified', action: 'mark_clarified', variant: 'success' },
          { label: 'Request More Info', action: 'request_info', variant: 'warning' },
          { label: 'Escalate to Manager', action: 'escalate', variant: 'danger' }
        ]
      case 'pending_dispatch_decision':
        return [
          { label: 'Approve Retry', action: 'approve_retry', variant: 'success' },
          { label: 'Suggest Alternative', action: 'suggest_alternative', variant: 'primary' },
          { label: 'Approve Refund', action: 'approve_refund', variant: 'warning' }
        ]
      case 'pending_customer_approval':
        return [
          { label: 'Customer Approved', action: 'customer_approved', variant: 'success' },
          { label: 'Customer Declined', action: 'customer_declined', variant: 'danger' },
          { label: 'Follow Up', action: 'follow_up', variant: 'info' }
        ]
      default:
        return []
    }
  }

  renderQuickActions(actions) {
    const container = this.quickActionsTarget
    container.innerHTML = actions.map(action => `
      <button type="button" 
              class="btn btn-${action.variant} btn-sm me-2 mb-2"
              data-action="click->unified-resolution#executeQuickAction"
              data-action="${action.action}">
        ${action.label}
      </button>
    `).join('')
  }

  loadConversationHistory() {
    if (!this.hasConversationTarget) return
    
    fetch(`/resolution/${this.refundIdValue}/conversation`)
      .then(response => response.text())
      .then(html => {
        this.conversationTarget.innerHTML = html
        this.scrollToBottom()
      })
  }

  scrollToBottom() {
    if (this.hasConversationTarget) {
      this.conversationTarget.scrollTop = this.conversationTarget.scrollHeight
    }
  }

  showTypingIndicator() {
    if (this.hasStatusIndicatorTarget) {
      this.statusIndicatorTarget.innerHTML = `
        <div class="typing-indicator">
          <span class="dot"></span>
          <span class="dot"></span>
          <span class="dot"></span>
        </div>
      `
    }
  }

  hideTypingIndicator() {
    if (this.hasStatusIndicatorTarget) {
      this.statusIndicatorTarget.innerHTML = ""
    }
  }

  showActionLoading(action) {
    const buttons = this.quickActionsTarget.querySelectorAll(`[data-action="${action}"]`)
    buttons.forEach(btn => {
      btn.disabled = true
      btn.innerHTML = `<span class="spinner-border spinner-border-sm me-1"></span>${btn.textContent}`
    })
  }

  hideActionLoading() {
    const buttons = this.quickActionsTarget.querySelectorAll('button[disabled]')
    buttons.forEach(btn => {
      btn.disabled = false
      btn.innerHTML = btn.textContent.replace(/.*?(<span.*?<\/span>)/, '')
    })
  }

  getCurrentMessageType() {
    const roleMap = {
      'pending_customer_clarification': 'agent',
      'pending_dispatch_decision': 'dispatcher', 
      'pending_customer_approval': 'agent',
      'resolution_completed': 'system'
    }
    return roleMap[this.currentStageValue] || 'agent'
  }

  isCriticalAction(action) {
    return ['approve_refund', 'escalate', 'customer_declined'].includes(action)
  }

  markAsViewed() {
    fetch(`/resolution/${this.refundIdValue}/mark_viewed`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
  }

  setupRealTimeUpdates() {
    // Listen for Turbo Stream updates
    document.addEventListener('turbo:before-stream-render', (event) => {
      if (event.target.getAttribute('id') === `refund_${this.refundIdValue}`) {
        this.updateProgressBar()
        this.setupQuickActions()
      }
    })
  }

  // Legacy methods for backward compatibility
  showModal(event) {
    event.preventDefault()
    this.showHub()
  }

  hideModal(event) {
    event.preventDefault()
    this.hideHub()
  }

  updateNotes(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    
    fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    })
  }

  updateStage(event) {
    event.preventDefault()
    const button = event.currentTarget
    const newStage = button.dataset.newStage
    
    if (newStage) {
      this.moveToStage(newStage)
    }
  }

  moveToStage(stage) {
    const url = `/resolution/${this.refundIdValue}/update_stage`
    const formData = new FormData()
    formData.append('resolution_stage', stage)
    
    fetch(url, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    }).then(() => {
      this.updateProgressBar()
      this.setupQuickActions()
    })
  }
}