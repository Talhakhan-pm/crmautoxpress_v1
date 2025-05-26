class Dispatch < ApplicationRecord
  belongs_to :order
  belongs_to :processing_agent, class_name: 'User'
  has_many :activities, as: :trackable, dependent: :destroy
  has_one :refund, dependent: :destroy

  enum payment_status: {
    payment_pending: 0,
    paid: 1,
    failed: 2,
    refunded: 3,
    partially_paid: 4
  }

  enum shipment_status: {
    shipment_pending: 10,
    picked_up: 11,
    in_transit: 12,
    delivered: 13,
    exception: 14,
    returned_to_sender: 15
  }

  enum dispatch_status: {
    pending: 20,
    assigned: 21,
    processing: 22,
    shipped: 23,
    completed: 24,
    cancelled: 25
  }

  # Validations
  validates :order_id, presence: true, uniqueness: true
  validates :order_number, presence: true
  validates :customer_name, presence: true
  validates :processing_agent_id, presence: true
  validates :dispatch_status, presence: true
  validates :payment_status, presence: true
  validates :shipment_status, presence: true
  validates :condition, presence: true, inclusion: { in: %w[new used refurbished] }
  validates :total_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :supplier_cost, numericality: { greater_than: 0 }, allow_blank: true
  validates :product_cost, numericality: { greater_than: 0 }, allow_blank: true

  # Callbacks
  before_validation :set_defaults, on: :create
  before_save :calculate_total_cost
  after_update :sync_with_order
  after_update :create_refund_if_cancelled
  
  include Trackable

  # Turbo Stream broadcasts
  after_create_commit { broadcast_dispatch_updates }
  after_update_commit { broadcast_dispatch_updates }
  after_destroy_commit { broadcast_dispatch_updates }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(dispatch_status: status) }
  scope :by_payment_status, ->(status) { where(payment_status: status) }
  scope :by_shipment_status, ->(status) { where(shipment_status: status) }
  scope :by_agent, ->(agent_id) { where(processing_agent_id: agent_id) }
  scope :by_supplier, ->(supplier) { where(supplier_name: supplier) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :pending_payment, -> { where(payment_status: :payment_pending) }
  scope :ready_to_ship, -> { where(dispatch_status: :processing, payment_status: :paid) }

  def status_color
    case dispatch_status
    when 'pending' then 'secondary'
    when 'assigned' then 'info'
    when 'processing' then 'warning'
    when 'shipped' then 'primary'
    when 'completed' then 'success'
    when 'cancelled' then 'danger'
    else 'secondary'
    end
  end

  def payment_status_color
    case payment_status
    when 'payment_pending' then 'warning'
    when 'paid' then 'success'
    when 'failed' then 'danger'
    when 'refunded' then 'info'
    when 'partially_paid' then 'warning'
    else 'secondary'
    end
  end

  def shipment_status_color
    case shipment_status
    when 'shipment_pending' then 'secondary'
    when 'picked_up' then 'info'
    when 'in_transit' then 'primary'
    when 'delivered' then 'success'
    when 'exception' then 'danger'
    when 'returned_to_sender' then 'warning'
    else 'secondary'
    end
  end

  def condition_color
    case condition
    when 'new' then 'success'
    when 'used' then 'warning'
    when 'refurbished' then 'info'
    else 'secondary'
    end
  end

  def profit_margin
    return 0 if product_cost.blank? || supplier_cost.blank?
    product_cost - supplier_cost
  end

  def profit_percentage
    return 0 if product_cost.blank? || supplier_cost.blank? || supplier_cost.zero?
    ((product_cost - supplier_cost) / supplier_cost * 100).round(2)
  end

  def can_be_shipped?
    processing? && paid? && supplier_order_number.present?
  end

  def can_be_cancelled?
    pending? || assigned?
  end

  def ready_for_completion?
    shipped? && delivered?
  end

  def has_tracking?
    tracking_number.present? || tracking_link.present?
  end

  def supplier_info
    return "No supplier assigned" if supplier_name.blank?
    return supplier_name if supplier_order_number.blank?
    "#{supplier_name} (Order: #{supplier_order_number})"
  end

  private

  def set_defaults
    self.dispatch_status ||= 'pending'
    self.payment_status ||= 'payment_pending'
    self.shipment_status ||= 'shipment_pending'
    self.condition ||= 'new'
  end

  def calculate_total_cost
    base_cost = product_cost || 0
    tax = tax_amount || 0
    shipping = shipping_cost || 0
    self.total_cost = base_cost + tax + shipping
  end

  def sync_with_order
    return unless order.present?

    # Update order status based on dispatch status
    case dispatch_status
    when 'processing'
      order.update!(order_status: 'processing') if order.confirmed?
    when 'shipped'
      order.update!(order_status: 'shipped', tracking_number: tracking_number)
    when 'completed'
      order.update!(order_status: 'delivered') if order.shipped?
    when 'cancelled'
      order.update!(order_status: 'cancelled')
    end

    # Update order tracking number if changed
    if tracking_number.present? && order.tracking_number != tracking_number
      order.update!(tracking_number: tracking_number)
    end

    # Update estimated delivery if we have tracking
    if shipped? && order.estimated_delivery.blank?
      estimated_date = Date.current + 3.days # Default 3-day shipping estimate
      order.update!(estimated_delivery: estimated_date)
    end
  end

  def broadcast_dispatch_updates
    return if Rails.env.test? || defined?(Rails::Console)
    
    Rails.logger.info "=== DISPATCH BROADCAST TRIGGERED ==="
    Rails.logger.info "Dispatch ##{id} status: #{dispatch_status}"
    
    # Broadcast to both flow streams and list view
    broadcast_to_flow_streams
    broadcast_to_list_view
    
    Rails.logger.info "=== DISPATCH BROADCAST SENT ==="
  end
  
  def broadcast_to_flow_streams
    # Get fresh data for each stream
    pending_dispatches = Dispatch.includes(:order).where(dispatch_status: ['pending', 'assigned']).recent
    processing_dispatches = Dispatch.includes(:order).where(dispatch_status: 'processing').recent
    shipped_dispatches = Dispatch.includes(:order).where(dispatch_status: 'shipped').recent
    completed_dispatches = Dispatch.includes(:order).where(dispatch_status: 'completed').recent.limit(10)
    
    # Broadcast to each flow stream
    broadcast_replace_to "dispatches", 
                        target: "pending-dispatches", 
                        partial: "dispatches/flow_stream_content", 
                        locals: { dispatches: pending_dispatches, status: 'pending' }
                        
    broadcast_replace_to "dispatches", 
                        target: "processing-dispatches", 
                        partial: "dispatches/flow_stream_content", 
                        locals: { dispatches: processing_dispatches, status: 'processing' }
                        
    broadcast_replace_to "dispatches", 
                        target: "shipped-dispatches", 
                        partial: "dispatches/flow_stream_content", 
                        locals: { dispatches: shipped_dispatches, status: 'shipped' }
                        
    broadcast_replace_to "dispatches", 
                        target: "completed-dispatches", 
                        partial: "dispatches/flow_stream_content", 
                        locals: { dispatches: completed_dispatches, status: 'completed' }
  end
  
  def broadcast_to_list_view
    # Broadcast to list view (existing functionality)
    fresh_dispatches = Dispatch.includes(:order).recent.limit(25)
    
    broadcast_replace_to "dispatches", 
                        target: "dispatches", 
                        partial: "dispatches/list_content", 
                        locals: { dispatches: fresh_dispatches }
  end

  def create_refund_if_cancelled
    return unless dispatch_status_changed? && cancelled? && refund.nil?
    
    # Map cancellation reason to refund reason
    mapped_reason = map_cancellation_to_refund_reason
    
    begin
      Refund.create!(
        order: self.order,
        dispatch: self,
        agent_name: self.processing_agent.email,
        customer_name: self.customer_name,
        customer_email: self.order&.customer_email || "#{self.customer_name.downcase.gsub(' ', '.')}@example.com",
        charge: self.total_cost,
        refund_amount: self.total_cost,
        refund_stage: 'pending_review',
        order_status: self.order&.order_status || 'cancelled',
        processing_agent: self.processing_agent,
        refund_reason: mapped_reason,
        order_summary: "Original dispatch ##{self.id} for #{self.product_name}. Reason: #{cancellation_reason&.humanize || 'Manual cancellation'}"
      )
      Rails.logger.info "✅ Refund created for cancelled dispatch ##{self.id}"
    rescue => e
      Rails.logger.error "❌ Failed to create refund for dispatch ##{self.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def map_cancellation_to_refund_reason
    case cancellation_reason
    when 'product_not_available' then 'product_not_found'
    when 'customer_requested_cancel' then 'customer_cancelled'
    when 'shipping_address_invalid' then 'address_invalid'
    when 'payment_failed' then 'payment_failed'
    else 'dispatch_cancelled'
    end
  end
end