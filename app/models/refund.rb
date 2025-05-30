class Refund < ApplicationRecord
  belongs_to :order
  belongs_to :processing_agent, class_name: 'User', optional: true
  has_many :activities, as: :trackable, dependent: :destroy

  enum refund_stage: {
    pending_refund: 0,
    processing_refund: 1,
    refunded: 2,
    pending_return: 3,
    returned: 4,
    urgent_refund: 5,
    failed_refund: 6,
    cancelled_refund: 7,
    pending_resolution: 8,
    pending_replacement: 9,
    pending_retry: 10
  }

  enum resolution_stage: {
    pending_customer_clarification: 0,
    pending_dispatch_decision: 1,
    pending_customer_approval: 2,
    resolution_completed: 3
  }

  enum refund_reason: {
    item_not_found: 0,
    item_sold_below_purchase: 1,
    customer_changed_mind: 2,
    wrong_product: 3,
    damaged_product: 4,
    quality_issues: 5,
    shipping_delay: 6,
    duplicate_order: 7,
    billing_error: 8,
    warranty_claim: 9,
    return_request: 10,
    other: 11
  }

  enum priority: {
    low: 0,
    standard: 1,
    high: 2,
    urgent: 3
  }

  enum refund_method: {
    original_payment: 0,
    store_credit: 1,
    bank_transfer: 2,
    check: 3,
    paypal: 4,
    venmo: 5
  }

  enum return_status: {
    no_return_required: 0,
    return_requested: 1,
    return_authorized: 2,
    return_label_sent: 3,
    return_shipped: 4,
    return_in_transit: 5,
    return_delivered: 6,
    return_received: 7,
    return_inspected: 8
  }

  # Validations
  validates :refund_number, presence: true, uniqueness: true
  validates :refund_date, presence: true
  validates :customer_name, presence: true
  validates :original_charge_amount, presence: true, numericality: { greater_than: 0 }
  validates :refund_amount, presence: true, numericality: { greater_than: 0 }
  validates :refund_stage, presence: true
  validates :refund_reason, presence: true

  # Callbacks
  before_validation :set_defaults, on: :create
  before_save :populate_from_order
  after_create :sync_order_status
  after_update :sync_order_status
  
  include Trackable

  # Turbo Stream broadcasts
  after_create_commit { broadcast_refunds_update unless Rails.env.test? || defined?(Rails::Console) }
  after_update_commit { broadcast_refunds_update unless Rails.env.test? || defined?(Rails::Console) }
  after_destroy_commit { broadcast_refunds_update unless Rails.env.test? || defined?(Rails::Console) }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_stage, ->(stage) { where(refund_stage: stage) }
  scope :by_reason, ->(reason) { where(refund_reason: reason) }
  scope :by_agent, ->(agent_id) { where(processing_agent_id: agent_id) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :today, -> { where(refund_date: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :pending, -> { where(refund_stage: [:pending_refund, :processing_refund, :pending_return, :pending_resolution, :pending_replacement, :pending_retry]) }
  scope :completed, -> { where(refund_stage: [:refunded, :returned]) }
  scope :overdue, -> { where(refund_date: ...3.days.ago).where.not(refund_stage: [:refunded, :returned, :cancelled_refund]) }
  scope :needs_escalation, -> { where(refund_date: ...3.days.ago).where(refund_stage: [:pending_refund, :processing_refund, :pending_return]) }
  scope :needs_resolution, -> { where(refund_stage: 'pending_resolution') }
  scope :by_resolution_stage, ->(stage) { where(resolution_stage: stage) }
  scope :awaiting_agent_action, -> { where(resolution_stage: 'pending_customer_clarification') }
  scope :awaiting_dispatcher_action, -> { where(resolution_stage: 'pending_dispatch_decision') }
  scope :awaiting_customer_action, -> { where(resolution_stage: 'pending_customer_approval') }

  def stage_color
    # Check for escalation first
    return 'danger' if needs_escalation? && !completed_stage?
    
    case refund_stage
    when 'pending_refund' then 'warning'
    when 'processing_refund' then 'info'
    when 'refunded' then 'success'
    when 'pending_return' then 'primary'
    when 'returned' then 'success'
    when 'urgent_refund' then 'danger'
    when 'failed_refund' then 'danger'
    when 'cancelled_refund' then 'secondary'
    when 'pending_resolution' then 'warning'
    when 'pending_replacement' then 'info'
    when 'pending_retry' then 'primary'
    else 'secondary'
    end
  end

  def priority_color
    case priority
    when 'low' then 'secondary'
    when 'standard' then 'info'
    when 'high' then 'warning'
    when 'urgent' then 'danger'
    else 'secondary'
    end
  end

  def reason_color
    case refund_reason
    when 'item_not_found', 'item_sold_below_purchase' then 'danger'
    when 'customer_changed_mind', 'return_request' then 'warning'
    when 'wrong_product', 'damaged_product', 'quality_issues' then 'danger'
    when 'billing_error', 'duplicate_order' then 'info'
    when 'warranty_claim' then 'primary'
    else 'secondary'
    end
  end

  def resolution_stage_color
    case resolution_stage
    when 'pending_customer_clarification' then 'warning'
    when 'pending_dispatch_decision' then 'info'
    when 'pending_customer_approval' then 'primary'
    when 'resolution_completed' then 'success'
    else 'secondary'
    end
  end

  def needs_resolution_action?
    refund_stage == 'pending_resolution' && !resolution_completed?
  end

  def resolution_stage_description
    case resolution_stage
    when 'pending_customer_clarification' then 'Agent needs to contact customer'
    when 'pending_dispatch_decision' then 'Dispatcher reviewing resolution options'
    when 'pending_customer_approval' then 'Waiting for customer approval'
    when 'resolution_completed' then 'Resolution process complete'
    else 'Resolution status unknown'
    end
  end

  def can_be_processed?
    pending_refund?
  end

  def can_be_cancelled?
    pending_refund? || processing_refund?
  end

  def requires_return?
    pending_return? || returned?
  end

  # Return Status Methods
  def return_status_color
    case return_status
    when 'no_return_required' then 'secondary'
    when 'return_requested' then 'warning'
    when 'return_authorized' then 'info'
    when 'return_label_sent' then 'primary'
    when 'return_shipped' then 'primary'
    when 'return_in_transit' then 'primary'
    when 'return_delivered' then 'success'
    when 'return_received' then 'success'
    when 'return_inspected' then 'success'
    else 'secondary'
    end
  end

  def return_requires_tracking?
    return_shipped? || return_in_transit? || return_delivered? || return_received?
  end

  def return_is_complete?
    return_received? || return_inspected?
  end

  def return_in_progress?
    return_authorized? || return_label_sent? || return_shipped? || return_in_transit?
  end

  def can_authorize_return?
    return_requested? && dispatcher_decision.present?
  end

  def can_generate_return_label?
    return_authorized? && return_label_url.blank?
  end

  def return_timeline_events
    events = []
    
    events << { status: 'return_requested', date: created_at, description: 'Return requested by customer' } if return_requested? || return_status_was_changed?
    events << { status: 'return_authorized', date: return_authorized_at, description: 'Return authorized by dispatcher' } if return_authorized_at.present?
    events << { status: 'return_label_sent', date: return_authorized_at, description: 'Return label generated and sent' } if return_label_sent? && return_label_url.present?
    events << { status: 'return_shipped', date: return_shipped_at, description: 'Customer shipped return package' } if return_shipped_at.present?
    events << { status: 'return_received', date: return_received_at, description: 'Return package received and inspected' } if return_received_at.present?
    
    events.compact.sort_by { |e| e[:date] || Time.current }
  end

  def days_since_return_requested
    return 0 unless return_requested? || return_in_progress? || return_is_complete?
    (Date.current - created_at.to_date).to_i
  end

  def return_sla_status
    return 'not_applicable' if no_return_required?
    return 'completed' if return_is_complete?
    
    days_elapsed = days_since_return_requested
    
    case days_elapsed
    when 0..7 then 'on_track'
    when 8..14 then 'at_risk'
    else 'overdue'
    end
  end

  def is_completed?
    refunded? || returned?
  end

  def days_since_request
    return 0 unless refund_date.present?
    (Date.current - refund_date.to_date).to_i
  end

  def estimated_completion_date
    return nil unless refund_date.present? && estimated_processing_days.present?
    refund_date.to_date + estimated_processing_days.days
  end

  def is_overdue?
    return false unless estimated_completion_date.present?
    Date.current > estimated_completion_date && !is_completed?
  end

  def refund_percentage
    return 0 if original_charge_amount.blank? || original_charge_amount.zero?
    (refund_amount / original_charge_amount * 100).round(2)
  end

  # Smart replacement order lookup with caching
  def replacement_order
    return nil unless replacement_order_number.present?
    
    # Use instance variable caching to avoid multiple DB queries
    @replacement_order ||= Order.find_by(order_number: replacement_order_number)
  end

  # Check if replacement order exists and is accessible
  def has_replacement_order?
    replacement_order_number.present? && replacement_order.present?
  end

  # Smart replacement order link - returns nil if order doesn't exist
  def replacement_order_link
    return nil unless has_replacement_order?
    replacement_order
  end

  # Get replacement order status with fallback
  def replacement_order_status
    return 'Order Not Found' unless has_replacement_order?
    replacement_order.display_status
  end

  # Check if replacement order is still active
  def replacement_order_active?
    has_replacement_order? && !['cancelled', 'refunded'].include?(replacement_order.order_status)
  end

  # Auto-escalation based on time
  def needs_escalation?
    return false if completed_stage?
    
    case refund_stage
    when 'pending_refund'
      refund_date < 3.days.ago
    when 'processing_refund'
      refund_date < 7.days.ago
    when 'pending_return'
      refund_date < 14.days.ago
    when 'pending_resolution'
      refund_date < 2.days.ago # Faster escalation for pending resolution
    else
      false
    end
  end

  def completed_stage?
    ['refunded', 'returned', 'cancelled_refund'].include?(refund_stage)
  end

  def escalation_days
    return 0 if completed_stage?
    
    case refund_stage
    when 'pending_refund' then 3
    when 'processing_refund' then 7
    when 'pending_return' then 14
    when 'pending_resolution' then 2
    else 0
    end
  end

  def auto_escalate_if_needed!
    return false unless needs_escalation?
    return false if urgent? # Already at highest priority
    
    old_stage = refund_stage
    old_priority = priority
    
    # Auto-escalate based on time rules
    case refund_stage
    when 'pending_refund'
      if refund_date < 3.days.ago
        update!(refund_stage: 'urgent_refund', priority: 'urgent')
      end
    when 'processing_refund'
      if refund_date < 7.days.ago
        update!(refund_stage: 'urgent_refund', priority: 'urgent')
      end
    when 'pending_return'
      if refund_date < 14.days.ago
        update!(refund_stage: 'urgent_refund', priority: 'urgent')
      end
    when 'pending_resolution'
      if refund_date < 2.days.ago
        update!(priority: 'urgent')
      end
    end
    
    # Log the escalation
    if refund_stage_changed? || priority_changed?
      create_activity(
        action: 'auto_escalated',
        details: "Auto-escalated from #{old_stage} (#{old_priority}) to #{refund_stage} (#{priority}) due to #{days_since_request} days elapsed",
        user: nil # System-generated
      )
      true
    else
      false
    end
  end

  # Class method to escalate all overdue refunds
  def self.escalate_overdue_refunds!
    needs_escalation.find_each do |refund|
      refund.auto_escalate_if_needed!
    end
  end

  # SLA Tracking & Performance Metrics
  def sla_target_days
    case refund_stage
    when 'pending_refund' then 3
    when 'processing_refund' then 7
    when 'pending_return' then 14
    when 'pending_resolution' then 2
    when 'pending_replacement' then 5
    when 'pending_retry' then 3
    else 7 # default
    end
  end

  def sla_deadline
    refund_date + sla_target_days.days
  end

  def sla_status
    return 'completed' if completed_stage?
    return 'breached' if Date.current > sla_deadline
    return 'at_risk' if Date.current >= (sla_deadline - 1.day)
    'on_track'
  end

  def sla_remaining_hours
    return 0 if completed_stage? || sla_status == 'breached'
    ((sla_deadline.end_of_day - Time.current) / 1.hour).round
  end

  def processing_time_hours
    return nil unless completed_at.present?
    ((completed_at - refund_date) / 1.hour).round(1)
  end

  def sla_performance_score
    return 100 if completed_stage? && processing_time_hours <= (sla_target_days * 24)
    return 0 if sla_status == 'breached'
    
    if completed_stage?
      # Completed but over SLA
      target_hours = sla_target_days * 24
      actual_hours = processing_time_hours
      [0, (100 - ((actual_hours - target_hours) / target_hours * 100)).round].max
    else
      # In progress scoring
      elapsed_hours = days_since_request * 24
      target_hours = sla_target_days * 24
      [0, (100 - (elapsed_hours / target_hours * 100)).round].max
    end
  end

  def agent_performance_impact
    case sla_performance_score
    when 90..100 then 'excellent'
    when 80..89 then 'good'
    when 70..79 then 'average'
    when 50..69 then 'below_average'
    else 'poor'
    end
  end

  # Class methods for analytics
  def self.sla_metrics(timeframe = 30.days)
    refunds = all # Get all refunds for now
    total_count = refunds.count
    
    if total_count.zero?
      return {
        on_track: 0,
        at_risk: 0,
        breached: 0,
        completed: 0,
        total_refunds: 0,
        avg_performance_score: 0,
        sla_compliance_rate: 0,
        avg_resolution_time: 0,
        total_escalations: 0
      }
    end

    # Calculate SLA status counts
    on_track_count = refunds.select { |r| r.sla_status == 'on_track' }.count
    at_risk_count = refunds.select { |r| r.sla_status == 'at_risk' }.count
    breached_count = refunds.select { |r| r.sla_status == 'breached' }.count
    completed_count = refunds.select { |r| r.sla_status == 'completed' }.count
    
    # Calculate performance metrics
    avg_performance_score = refunds.map(&:sla_performance_score).sum.to_f / total_count
    sla_compliance_rate = ((total_count - breached_count).to_f / total_count * 100)
    
    # Calculate resolution time for completed refunds
    completed_refunds = refunds.select { |r| r.completed_stage? && r.processing_time_hours.present? }
    avg_resolution_time = if completed_refunds.any?
      completed_refunds.map { |r| r.processing_time_hours / 24 }.sum.to_f / completed_refunds.count
    else
      0
    end
    
    # Count escalations (urgent priority items)
    total_escalations = refunds.select { |r| r.priority == 'urgent' }.count

    {
      on_track: on_track_count,
      at_risk: at_risk_count,
      breached: breached_count,
      completed: completed_count,
      total_refunds: total_count,
      avg_performance_score: avg_performance_score.round(1),
      sla_compliance_rate: sla_compliance_rate.round(1),
      avg_resolution_time: avg_resolution_time.round(1),
      total_escalations: total_escalations
    }
  end

  def self.agent_performance_metrics(timeframe = 30.days)
    # Get all refunds grouped by agent
    all_refunds = all
    agent_stats = {}
    
    # Group by processing_agent_id
    all_refunds.group_by(&:processing_agent_id).each do |agent_id, agent_refunds|
      next if agent_refunds.empty?
      
      completed_refunds = agent_refunds.select(&:completed_stage?)
      total_score = agent_refunds.map(&:sla_performance_score).sum
      avg_score = total_score.to_f / agent_refunds.count
      
      # Calculate resolution time in days
      avg_resolution_time = if completed_refunds.any? && completed_refunds.any? { |r| r.processing_time_hours.present? }
        completed_refunds.select { |r| r.processing_time_hours.present? }
                         .map { |r| r.processing_time_hours / 24 }
                         .sum.to_f / completed_refunds.select { |r| r.processing_time_hours.present? }.count
      else
        0
      end
      
      breach_count = agent_refunds.select { |r| r.sla_status == 'breached' }.count
      sla_compliance_rate = ((agent_refunds.count - breach_count).to_f / agent_refunds.count * 100)
      
      agent_stats[agent_id] = {
        total_refunds: agent_refunds.count,
        avg_performance_score: avg_score.round(1),
        sla_compliance_rate: sla_compliance_rate.round(1),
        avg_resolution_time: avg_resolution_time.round(1),
        total_escalations: agent_refunds.select { |r| r.priority == 'urgent' }.count
      }
    end
    
    agent_stats
  end

  def self.stage_performance_breakdown(timeframe = 30.days)
    all_refunds = all
    breakdown = {}
    
    refund_stages.keys.each do |stage|
      stage_refunds = all_refunds.select { |r| r.refund_stage == stage }
      next if stage_refunds.empty?

      # Calculate average score and days for this stage
      avg_score = stage_refunds.map(&:sla_performance_score).sum.to_f / stage_refunds.count
      
      # Calculate average days for completed refunds in this stage
      completed_stage_refunds = stage_refunds.select { |r| r.completed_stage? && r.processing_time_hours.present? }
      avg_days = if completed_stage_refunds.any?
        completed_stage_refunds.map { |r| r.processing_time_hours / 24 }.sum.to_f / completed_stage_refunds.count
      else
        0
      end

      breakdown[stage] = {
        count: stage_refunds.count,
        avg_score: avg_score.round(1),
        avg_days: avg_days.round(1)
      }
    end
    
    breakdown
  end

  private

  def broadcast_refunds_update
    Rails.logger.info "=== REFUNDS BROADCAST TRIGGERED ==="
    
    fresh_refunds = Refund.includes(:order, :processing_agent).recent.limit(25)
    
    broadcast_replace_to "refunds", 
                        target: "refunds-content", 
                        partial: "refunds/refunds_content", 
                        locals: { refunds: fresh_refunds }
                        
    Rails.logger.info "=== REFUNDS BROADCAST SENT ==="
  end

  def set_defaults
    self.refund_number ||= generate_refund_number
    self.refund_date ||= Time.current
    self.priority ||= 'standard'
    self.estimated_processing_days ||= 7
    
    # Set initial stage based on refund reason
    if self.refund_stage.blank?
      if ['wrong_product', 'defective_product', 'quality_issues'].include?(self.refund_reason)
        # Return-eligible reasons start in resolution workflow
        self.refund_stage = 'pending_resolution'
        self.resolution_stage = 'pending_customer_clarification'
        self.return_status = 'return_requested'
      else
        # Non-return reasons go straight to pending refund
        self.refund_stage = 'pending_refund'
        self.return_status = 'no_return_required'
      end
    end
  end

  def generate_refund_number
    prefix = "RF"
    timestamp = Time.current.strftime("%Y%m%d")
    sequence = Refund.where("refund_number LIKE ?", "#{prefix}#{timestamp}%").count + 1
    "#{prefix}#{timestamp}#{sequence.to_s.rjust(3, '0')}"
  end

  def populate_from_order
    return unless order.present?
    
    self.customer_name ||= order.customer_name
    self.customer_email ||= order.customer_email
    self.order_status ||= order.order_status
    self.agent_name ||= order.agent&.email
    self.original_charge_amount ||= order.total_amount
    self.processing_agent_id ||= order.processing_agent_id || order.agent_id
  end

  def sync_order_status
    return unless order.present?
    old_stage = refund_stage_was
    
    case refund_stage
    when 'refunded', 'returned'
      # When refund is completed, cancel the order
      order.update!(order_status: 'cancelled') unless order.cancelled?
      
      # Update dispatch status and payment status if exists
      if order.dispatch.present?
        order.dispatch.update!(
          dispatch_status: 'cancelled',
          payment_status: 'refunded'
        )
      end
      
      # Create activity for order cancellation due to refund
      order.create_activity(
        action: 'cancelled_by_refund',
        details: "Order cancelled due to completed refund #{refund_number} - $#{refund_amount}",
        user: Current.user || processing_agent
      )
      
    when 'pending_return'
      order.update!(order_status: 'returned') unless order.returned?
    when 'processing_refund'
      # Create activity for processing
      create_activity(
        action: 'refund_processing',
        details: "Refund processing started - $#{refund_amount}",
        user: Current.user
      )
    when 'pending_refund'
      # When refund moves to pending_refund, immediately cancel order/dispatch
      Rails.logger.info "DEBUG: Refund #{id} entering pending_refund stage, cancelling order #{order.id}"
      Rails.logger.info "DEBUG: Order status before update: #{order.order_status}"
      Rails.logger.info "DEBUG: Order cancelled?: #{order.cancelled?}"
      
      unless order.cancelled?
        Rails.logger.info "DEBUG: About to update order status to cancelled"
        begin
          order.update!(order_status: 'cancelled')
          Rails.logger.info "DEBUG: Order update successful"
        rescue => e
          Rails.logger.error "DEBUG: Order update failed: #{e.message}"
          Rails.logger.error "DEBUG: Order errors: #{order.errors.full_messages}"
        end
      end
      
      if order.dispatch.present?
        Rails.logger.info "DEBUG: Dispatch status before update: #{order.dispatch.dispatch_status}"
        order.dispatch.update!(dispatch_status: 'cancelled') unless order.dispatch.cancelled?
        Rails.logger.info "DEBUG: Dispatch status after update: #{order.dispatch.reload.dispatch_status}"
      end
      
      # Create activity for immediate cancellation
      order.create_activity(
        action: 'cancelled_by_refund_request',
        details: "Order cancelled due to refund request #{refund_number} - Reason: #{refund_reason.humanize}",
        user: Current.user || processing_agent
      )
      
      Rails.logger.info "DEBUG: Order #{order.id} status after cancellation: #{order.reload.order_status}"
    when 'pending_resolution'
      # For pending_resolution stage, DO NOT cancel the order
      # Just create activity to track the resolution request
      order.create_activity(
        action: 'resolution_requested',
        details: "Resolution requested for #{refund_reason.humanize} - #{refund_number}",
        user: Current.user || processing_agent
      )
    end
    
    # Broadcast updates when stage changes
    if old_stage != refund_stage
      broadcast_unified_updates
    end
  end

  def broadcast_unified_updates
    # Trigger broadcasts for order and dispatch views as well
    order.send(:broadcast_orders_update) if order.present?
    order.dispatch.send(:broadcast_dispatch_updates) if order.dispatch.present?
  end

  def create_replacement_order
    return nil unless order.present?
    return replacement_order if replacement_order_number.present?
    
    # Create new order as replacement
    replacement = Order.create!(
      customer_name: order.customer_name,
      customer_address: order.customer_address,
      customer_phone: order.customer_phone,
      customer_email: order.customer_email,
      product_name: order.product_name,
      car_year: order.car_year,
      car_make_model: order.car_make_model,
      product_price: order.product_price,
      tax_amount: order.tax_amount,
      shipping_cost: order.shipping_cost,
      total_amount: order.total_amount,
      agent_id: order.agent_id,
      processing_agent_id: processing_agent_id,
      priority: 'high', # Replacements should be high priority
      source_channel: 'replacement',
      order_status: 'confirmed',
      comments: "Replacement order for #{order.order_number} (Refund: #{refund_number})"
    )
    
    # Link the replacement
    update!(replacement_order_number: replacement.order_number)
    
    # Create activities
    create_activity(
      action: 'replacement_created',
      details: "Replacement order #{replacement.order_number} created",
      user: Current.user
    )
    
    replacement.create_activity(
      action: 'created_as_replacement',
      details: "Created as replacement for order #{order.order_number}",
      user: Current.user
    )
    
    replacement
  end

  # Resolution Actions for Returns
  def authorize_return_and_refund!
    return false unless pending_resolution?
    
    transaction do
      update!(
        resolution_stage: 'resolution_completed',
        dispatcher_decision: 'authorize_return_and_refund',
        return_status: 'return_authorized',
        return_authorized_at: Time.current,
        refund_stage: 'pending_return'
      )
      
      create_activity(
        action: 'return_authorized',
        details: "Return authorized for full refund - Customer to ship back #{order.product_name}",
        user: Current.user
      )
    end
  end

  def authorize_return_and_replacement!
    return false unless pending_resolution?
    
    transaction do
      # Create replacement order first
      replacement = create_replacement_order
      
      update!(
        resolution_stage: 'resolution_completed',
        dispatcher_decision: 'authorize_return_and_replacement',
        return_status: 'return_authorized',
        return_authorized_at: Time.current,
        replacement_order_number: replacement.order_number
      )
      
      create_activity(
        action: 'return_and_replacement_authorized',
        details: "Return authorized with replacement order #{replacement.order_number}",
        user: Current.user
      )
      
      replacement
    end
  end

  def generate_return_label!(carrier: 'FedEx', label_url: nil)
    return false unless can_generate_return_label?
    
    update!(
      return_status: 'return_label_sent',
      return_carrier: carrier,
      return_label_url: label_url || "https://example.com/return-labels/#{id}",
      return_deadline: 14.days.from_now
    )
    
    create_activity(
      action: 'return_label_generated',
      details: "Return label generated via #{carrier} - Customer has 14 days to ship",
      user: Current.user
    )
  end

  def mark_return_shipped!(tracking_number: nil)
    return false unless return_label_sent?
    
    update!(
      return_status: 'return_shipped',
      return_tracking_number: tracking_number || return_tracking_number,
      return_shipped_at: Time.current
    )
    
    create_activity(
      action: 'return_shipped',
      details: "Customer shipped return package - Tracking: #{return_tracking_number}",
      user: Current.user
    )
  end

  def mark_return_received!(condition_notes: nil)
    return false unless return_shipped? || return_in_transit? || return_delivered?
    
    update!(
      return_status: 'return_received',
      return_received_at: Time.current,
      return_notes: condition_notes || return_notes,
      refund_stage: 'processing_refund'
    )
    
    create_activity(
      action: 'return_received',
      details: "Return package received and inspected#{condition_notes.present? ? ' - ' + condition_notes : ''}",
      user: Current.user
    )
  end

end
