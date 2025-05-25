class Order < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :product, optional: true
  belongs_to :agent, class_name: 'User'
  belongs_to :processing_agent, class_name: 'User', optional: true
  belongs_to :agent_callback, optional: true
  has_one :dispatch, dependent: :destroy
  has_many :activities, as: :trackable, dependent: :destroy

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
  after_create :create_dispatch_record
  
  include Trackable

  # Turbo Stream broadcasts
  # after_create_commit { broadcast_prepend_to "orders", target: "orders" }
  # after_update_commit { broadcast_replace_to "orders" }
  # after_destroy_commit { broadcast_remove_to "orders" }

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

  private

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
    sequence = Order.where("order_number LIKE ?", "#{prefix}#{timestamp}%").count + 1
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
      last_modified_by: last_modified_by
    }
    
    create_dispatch!(dispatch_attributes)
  end
end