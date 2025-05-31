class Order < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :product, optional: true
  belongs_to :agent, class_name: 'User'
  belongs_to :processing_agent, class_name: 'User', optional: true
  belongs_to :agent_callback, optional: true
  belongs_to :supplier, optional: true
  has_one :dispatch, dependent: :destroy
  has_one :refund, dependent: :destroy
  has_many :activities, as: :trackable, dependent: :destroy
  
  # Replacement order relationships
  belongs_to :original_order, class_name: 'Order', optional: true
  has_one :replacement_order, class_name: 'Order', foreign_key: 'original_order_id', dependent: :destroy

  enum order_status: {
    pending: 0,
    confirmed: 1,
    processing: 2,
    shipped: 3,
    delivered: 4,
    cancelled: 5,
    returned: 6,
    refunded: 7
  }

  enum priority: {
    low: 0,
    standard: 1,
    high: 2,
    rush: 3,
    urgent: 4
  }

  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :order_date, presence: true
  validates :customer_name, presence: true
  validates :product_name, presence: true
  validates :order_status, presence: true
  validates :agent_id, presence: true
  validates :priority, presence: true
  validates :source_channel, presence: true
  validates :product_price, presence: true, numericality: { greater_than: 0 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :warranty_period_days, numericality: { greater_than: 0 }, allow_blank: true
  validates :return_window_days, numericality: { greater_than: 0 }, allow_blank: true
  validates :car_year, numericality: { 
    greater_than: 1900, 
    less_than_or_equal_to: Date.current.year + 2 
  }, allow_blank: true

  # Callbacks
  before_validation :set_defaults, on: :create
  before_save :calculate_total_amount
  after_create :find_or_create_customer
  after_create :find_or_create_product
  after_create :find_or_create_supplier
  after_create :create_dispatch_record
  after_create :create_auto_callback
  after_update :sync_with_dispatch
  after_update :update_supplier_total_orders
  
  include Trackable

  # Turbo Stream broadcasts - with seeding guard
  after_create_commit { broadcast_orders_update unless Rails.env.test? || defined?(Rails::Console) }
  after_update_commit { broadcast_orders_update unless Rails.env.test? || defined?(Rails::Console) }
  after_destroy_commit { broadcast_orders_update unless Rails.env.test? || defined?(Rails::Console) }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(order_status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_agent, ->(agent_id) { where(agent_id: agent_id) }
  scope :today, -> { where(order_date: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(order_date: Date.current.beginning_of_week..Date.current.end_of_week) }

  def full_customer_info
    if customer.present?
      "#{customer.name} (#{customer.phone_number})"
    else
      "#{customer_name} (#{customer_phone})"
    end
  end

  def vehicle_info
    return nil unless car_year.present? || car_make_model.present?
    "#{car_year} #{car_make_model}".strip
  end

  def status_color
    # Check for pending refund resolution first
    if has_pending_refund_resolution?
      return 'warning'
    end
    
    case order_status
    when 'pending' then 'warning'
    when 'confirmed' then 'info'
    when 'processing' then 'primary'
    when 'shipped' then 'success'
    when 'delivered' then 'success'
    when 'cancelled' then 'danger'
    when 'returned' then 'warning'
    when 'refunded' then 'secondary'
    else 'secondary'
    end
  end
  
  def display_status
    # Show pending resolution status if applicable
    if has_pending_refund_resolution?
      return 'Pending Resolution'
    end
    
    # Otherwise show normal status
    order_status.humanize
  end
  
  def has_pending_refund_resolution?
    return false unless refund.present?
    ['pending_resolution', 'pending_retry', 'pending_replacement'].include?(refund.refund_stage)
  end

  def priority_color
    case priority
    when 'low' then 'secondary'
    when 'standard' then 'info'
    when 'high' then 'warning'
    when 'rush' then 'danger'
    when 'urgent' then 'danger'
    else 'secondary'
    end
  end

  def can_be_cancelled?
    pending? || confirmed?
  end

  def can_be_shipped?
    confirmed? || processing?
  end

  def profit_margin
    return 0 if product_price.blank? || dispatch&.supplier_cost.blank?
    product_price - dispatch.supplier_cost
  end

  # Unified status badges for orders, dispatches, and refunds
  def unified_status_badges
    badges = []
    
    # Primary order status (with intelligent pending resolution detection)
    badges << {
      type: 'order',
      status: has_pending_refund_resolution? ? 'pending_resolution' : order_status,
      color: status_color,
      text: display_status,
      priority: 1,
      pulsing: has_pending_refund_resolution?
    }
    
    # Dispatch status if exists
    if dispatch.present?
      badges << {
        type: 'dispatch',
        status: dispatch.dispatch_status,
        color: dispatch.status_color,
        text: "Dispatch: #{dispatch.dispatch_status.humanize}",
        priority: 2
      }
      
      # Payment status
      unless dispatch.payment_pending?
        badges << {
          type: 'payment',
          status: dispatch.payment_status,
          color: dispatch.payment_status_color,
          text: "Payment: #{dispatch.payment_status.humanize}",
          priority: 3
        }
      end
    end
    
    # Refund status if exists
    if refund.present?
      refund_text = refund.refund_stage.humanize
      
      # Special handling for pending resolution
      if refund.refund_stage == 'pending_resolution'
        refund_text = "Needs Resolution"
      end
      
      badges << {
        type: 'refund',
        status: refund.refund_stage,
        color: refund.stage_color,
        text: "Refund: #{refund_text}",
        priority: 4,
        pulsing: refund.refund_stage == 'pending_resolution'
      }
    end
    
    badges.sort_by { |badge| badge[:priority] }
  end

  # Unified timeline combining order, dispatch, and refund activities
  def unified_timeline(limit = 10)
    timeline_items = []
    
    # Order activities
    timeline_items += activities.includes(:user).map do |activity|
      {
        type: 'order',
        timestamp: activity.created_at,
        action: activity.action,
        details: activity.details,
        user: activity.user,
        model: self,
        activity: activity
      }
    end
    
    # Dispatch activities
    if dispatch.present?
      timeline_items += dispatch.activities.includes(:user).map do |activity|
        {
          type: 'dispatch',
          timestamp: activity.created_at,
          action: activity.action,
          details: activity.details,
          user: activity.user,
          model: dispatch,
          activity: activity
        }
      end
    end
    
    # Refund activities
    if refund.present?
      timeline_items += refund.activities.includes(:user).map do |activity|
        {
          type: 'refund',
          timestamp: activity.created_at,
          action: activity.action,
          details: activity.details,
          user: activity.user,
          model: refund,
          activity: activity
        }
      end
    end
    
    # Sort by timestamp and limit
    timeline_items.sort_by { |item| item[:timestamp] }.reverse.first(limit)
  end

  def has_active_refund?
    refund.present? && refund.pending?
  end

  def has_completed_refund?
    refund.present? && refund.completed?
  end

  def total_refunded_amount
    return 0 unless refund.present? && ['refunded', 'returned'].include?(refund.refund_stage)
    refund.refund_amount
  end

  def refund_status_summary
    return nil unless refund.present?
    
    if refund.pending?
      "Pending refund"
    elsif refund.completed?
      "Refunded: $#{refund.refund_amount}"
    end
  end

  # Replacement order methods
  def is_replacement_order?
    original_order_id.present?
  end

  def has_replacement_order?
    replacement_order_id.present?
  end

  def replacement_chain_info
    if is_replacement_order?
      "Replacement for Order ##{original_order.order_number} (#{replacement_reason&.humanize})"
    elsif has_replacement_order?
      "Replaced by Order ##{replacement_order.order_number}"
    else
      nil
    end
  end


  private

  def broadcast_orders_update
    Rails.logger.info "=== ORDERS BROADCAST TRIGGERED ==="
    
    # Fetch fresh orders data with the same logic as controller
    fresh_orders = Order.includes(:customer, :product, :agent, :processing_agent, :dispatch, :refund)
                        .recent
                        .limit(25)
    
    Rails.logger.info "Broadcasting #{fresh_orders.count} orders"
    
    broadcast_replace_to "orders", 
                        target: "orders-content", 
                        partial: "orders/orders_content", 
                        locals: { orders: fresh_orders, view_type: 'cards' }
                        
    Rails.logger.info "=== ORDERS BROADCAST SENT ==="
  end

  def set_defaults
    self.order_number ||= generate_order_number
    self.order_date ||= Time.current
    self.priority ||= 'standard'
    self.order_status ||= 'pending'
    self.source_channel ||= 'phone'
    self.processing_agent_id ||= agent_id
  end

  def generate_order_number
    prefix = "AX"
    timestamp = Time.current.strftime("%Y%m%d")
    sequence = Order.where(Order.arel_table[:order_number].matches("#{prefix}#{timestamp}%")).count + 1
    "#{prefix}#{timestamp}#{sequence.to_s.rjust(3, '0')}"
  end

  def calculate_total_amount
    base_amount = product_price || 0
    tax = tax_amount || 0
    shipping = shipping_cost || 0
    self.total_amount = base_amount + tax + shipping
  end

  def create_dispatch_record
    return if dispatch.present?
    
    dispatch_attributes = {
      order_number: order_number,
      customer_name: customer_name,
      customer_address: customer_address,
      product_name: product_name,
      car_details: vehicle_info,
      processing_agent_id: processing_agent_id || agent_id,
      product_cost: product_price,
      tax_amount: tax_amount,
      shipping_cost: shipping_cost,
      total_cost: total_amount,
      payment_status: 'paid', # Auto-set payment as paid when order is created
      last_modified_by: last_modified_by
    }
    
    create_dispatch!(dispatch_attributes)
  end

  def find_or_create_customer
    return if customer_phone.blank? || customer_name.blank?
    
    Rails.logger.info "=== AUTO-CREATING CUSTOMER FROM ORDER ==="
    Rails.logger.info "Phone: #{customer_phone}, Name: #{customer_name}"
    
    existing_customer = Customer.find_by(phone_number: customer_phone)
    
    unless existing_customer
      Customer.create!(
        phone_number: customer_phone,
        name: customer_name,
        email: customer_email,
        address: customer_address,
        source_campaign: 'order'
      )
      Rails.logger.info "Created new customer: #{customer_name} from order"
    else
      Rails.logger.info "Customer already exists: #{existing_customer.name}"
    end
    
  rescue => e
    Rails.logger.error "Customer auto-creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def find_or_create_product
    return if product_name.blank?
    
    Rails.logger.info "=== AUTO-CREATING PRODUCT FROM ORDER ==="
    Rails.logger.info "Product: #{product_name}"
    
    # Check if product already exists (by name similarity)
    existing_product = Product.where(Product.arel_table[:name].matches("%#{product_name.strip}%")).first
    
    unless existing_product
      # Generate a simple part number from the product name
      part_number = generate_product_part_number(product_name)
      
      # Try to guess category from product name
      category = guess_product_category(product_name)
      
      Product.create!(
        name: product_name.strip,
        part_number: part_number,
        category: category,
        description: "Auto-created from Order ##{order_number}",
        vendor_cost: product_price * 0.7, # Estimate 70% cost ratio
        selling_price: product_price,
        source: 'order',
        status: 'active'
      )
      
      Rails.logger.info "Created new product: #{product_name} from order"
    else
      Rails.logger.info "Product already exists: #{existing_product.name}"
    end
    
  rescue => e
    Rails.logger.error "Product auto-creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def find_or_create_supplier
    # This method will be called when supplier data is available
    # For now, suppliers will be created manually or via dispatch updates
    # We'll implement auto-creation when we add supplier creation workflow
  end
  
  def update_supplier_total_orders
    return unless supplier.present?
    supplier.update_total_orders!
  end

  def create_auto_callback
    # Skip if this order was already created from a callback
    return if agent_callback_id.present?
    
    Rails.logger.info "=== AUTO-CREATING CALLBACK FROM ORDER ==="
    Rails.logger.info "Order ##{order_number} - Customer: #{customer_name}"
    
    begin
      auto_callback = AgentCallback.create!(
        user: agent,
        customer_name: customer_name,
        phone_number: customer_phone,
        product: product_name,
        status: 'sale', # Mark as successful sale
        notes: "Auto-generated from Order ##{order_number}. Direct sale via #{source_channel}.",
        created_at: order_date,
        updated_at: Time.current
      )
      
      # Link the callback to this order
      update_column(:agent_callback_id, auto_callback.id)
      
      Rails.logger.info "Created auto-callback ##{auto_callback.id} for order ##{order_number}"
      
      auto_callback
    rescue => e
      Rails.logger.error "Auto-callback creation failed for order ##{order_number}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def generate_product_part_number(name)
    # Simple part number generation
    prefix = name.split.first&.upcase&.first(3) || "ORD"
    timestamp = Time.current.strftime("%m%d%H%M")
    "#{prefix}-#{timestamp}"
  end
  
  def guess_product_category(name)
    name_lower = name.downcase
    
    case name_lower
    when /brake|pad|rotor|caliper/
      'brakes'
    when /engine|motor|piston|valve/
      'engine'
    when /shock|strut|spring|suspension/
      'suspension'
    when /wire|electric|battery|alternator/
      'electrical'
    when /bumper|door|fender|body/
      'body'
    when /seat|interior|carpet|console/
      'interior'
    when /transmission|gear|clutch/
      'transmission'
    when /radiator|cooling|fan|thermostat/
      'cooling'
    when /exhaust|muffler|pipe|catalytic/
      'exhaust'
    else
      'engine' # Default category
    end
  end

  def sync_with_dispatch
    return unless dispatch.present?

    # Update dispatch status based on order status
    case order_status
    when 'cancelled'
      dispatch.update!(dispatch_status: 'cancelled') unless dispatch.cancelled?
    when 'confirmed'
      dispatch.update!(dispatch_status: 'assigned') if dispatch.pending?
    when 'processing'
      # DON'T override cancelled dispatches - manual cancellation should stay cancelled
      # Only update if dispatch is in a state that allows processing
      dispatch.update!(dispatch_status: 'processing') if dispatch.assigned?
    end
  end
end