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
    cancelled_refund: 7
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
  scope :pending, -> { where(refund_stage: [:pending_refund, :processing_refund, :pending_return]) }
  scope :completed, -> { where(refund_stage: [:refunded, :returned]) }

  def stage_color
    case refund_stage
    when 'pending_refund' then 'warning'
    when 'processing_refund' then 'info'
    when 'refunded' then 'success'
    when 'pending_return' then 'primary'
    when 'returned' then 'success'
    when 'urgent_refund' then 'danger'
    when 'failed_refund' then 'danger'
    when 'cancelled_refund' then 'secondary'
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

  def can_be_processed?
    pending_refund?
  end

  def can_be_cancelled?
    pending_refund? || processing_refund?
  end

  def requires_return?
    pending_return? || returned?
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
    self.refund_stage ||= 'pending_refund'
    self.estimated_processing_days ||= 7
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
    
    case refund_stage
    when 'refunded', 'returned'
      order.update!(order_status: 'refunded') unless order.refunded?
    when 'pending_return'
      order.update!(order_status: 'returned') unless order.returned?
    end
  end
end
