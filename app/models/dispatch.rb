class Dispatch < ApplicationRecord
  belongs_to :order
  belongs_to :processing_agent, class_name: 'User'
  has_many :activities, as: :trackable, dependent: :destroy
  has_one :refund, through: :order

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
  validates :product_cost, numericality: { greater_than: 0 }, allow_blank: true

  # Callbacks
  before_validation :set_defaults, on: :create
  before_save :calculate_total_cost
  after_update :sync_with_order
  after_update :send_shipping_notification_on_status_change
  
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
  scope :by_supplier, ->(supplier) { joins(order: :supplier).where(suppliers: { name: supplier }) }
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
    return 0 if product_cost.blank? || order.supplier_cost.blank?
    product_cost - order.supplier_cost
  end

  def profit_percentage
    return 0 if product_cost.blank? || order.supplier_cost.blank? || order.supplier_cost.zero?
    ((product_cost - order.supplier_cost) / order.supplier_cost * 100).round(2)
  end

  def can_be_shipped?
    processing? && paid? && order.supplier_order_number.present?
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

  def shipped_or_completed?
    shipped? || completed?
  end

  def supplier_info
    return "No supplier assigned" unless order.supplier.present?
    return order.supplier.name if order.supplier_order_number.blank?
    "#{order.supplier.name} (Order: #{order.supplier_order_number})"
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
    old_status = dispatch_status_was
    
    # Skip sync if we're already in a sync operation to prevent circular calls
    return if @syncing_with_order
    @syncing_with_order = true
    
    begin
      # Auto-resolve any pending resolutions if applicable
      if order.refund.present? && order.refund.pending_resolution?
        order.refund.auto_complete_resolution_if_resolved!
      end
      
      # Update order status based on dispatch status (unless blocked by active refund processing)
      unless order.refund.present? && order.refund.refund_stage.in?(['pending_refund', 'processing_refund'])
        case dispatch_status
        when 'pending'
          # Dispatch moved to pending - order should be pending too
          order.update!(order_status: 'pending') unless order.pending?
        when 'assigned'
          # Dispatch assigned - order should be confirmed
          order.update!(order_status: 'confirmed') unless order.confirmed?
        when 'processing'
          order.update!(order_status: 'processing') if order.confirmed?
        when 'shipped'
          order.update!(order_status: 'shipped', tracking_number: tracking_number)
        when 'completed'
          # Allow transition from confirmed, processing, or shipped to delivered
          if order.confirmed? || order.processing? || order.shipped?
            order.update!(order_status: 'delivered')
          end
        when 'cancelled'
          # Order status update only - refund creation handled by controller for custom amounts/reasons
          order.update!(order_status: 'processing')
          
          # Create activity for the cancellation
          create_activity(
            action: 'dispatch_cancelled',
            details: "Dispatch cancelled - Awaiting resolution decision",
            user: Current.user
          )
        end
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

      # Handle payment status changes that affect refunds
      sync_payment_with_refunds if payment_status_changed?
    ensure
      @syncing_with_order = false
    end
  end

  def handle_dispatch_cancellation
    # Keep order in processing state (don't cancel immediately)
    order.update!(order_status: 'processing')
    
    # Auto-create refund with resolution options
    if paid? || partially_paid?
      create_auto_refund_for_cancellation
    end
    
    # Create activity for the cancellation
    create_activity(
      action: 'dispatch_cancelled',
      details: "Dispatch cancelled - Awaiting resolution decision",
      user: Current.user
    )
  end

  def create_auto_refund_for_cancellation
    return if order.refund.present? # Don't create duplicate refunds (1:1 relationship)
    
    refund_amount = calculate_refund_amount_for_cancellation
    
    refund = order.create_refund!(
      processing_agent: processing_agent,
      customer_name: customer_name,
      customer_email: order.customer_email,
      original_charge_amount: total_cost,
      refund_amount: refund_amount,
      refund_stage: 'pending_resolution', # New stage for resolution options
      refund_reason: 'item_not_found', # More accurate for dispatch cancellation
      priority: 'high', # Cancellations should be high priority
      notes: "Dispatch cancelled - Choose resolution: Retry, Replace, or Refund",
      last_modified_by: Current.user&.email || 'system'
    )
    
    # Create linked activity
    refund.create_activity(
      action: 'auto_refund_created',
      details: "Refund automatically created due to dispatch cancellation",
      user: Current.user
    )
  end

  def calculate_refund_amount_for_cancellation
    case payment_status
    when 'paid'
      total_cost # Full refund
    when 'partially_paid'
      # Calculate partial refund based on amount paid
      # This would need to be enhanced based on your payment tracking
      total_cost * 0.5 # Default to 50% for partial payments
    else
      0
    end
  end

  def sync_payment_with_refunds
    return unless order.refund.present?
    
    case payment_status
    when 'refunded'
      # Update pending refund to completed
      if order.refund.pending?
        order.refund.update!(
          refund_stage: 'refunded',
          completed_at: Time.current
        )
      end
    when 'failed'
      # Mark refund as urgent if payment failed
      if order.refund.pending?
        order.refund.update!(refund_stage: 'urgent_refund')
      end
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

  # Email automation for shipping notifications
  def send_shipping_notification_on_status_change
    # Only send shipping notification when dispatch status changes to 'shipped'
    # or when tracking number is added
    if saved_change_to_dispatch_status? && dispatch_status == 'shipped'
      order.send_shipping_notification_email
    elsif saved_change_to_tracking_number? && tracking_number.present? && shipped?
      order.send_shipping_notification_email
    end
  end
end