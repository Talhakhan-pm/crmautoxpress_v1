class Invoice < ApplicationRecord
  belongs_to :agent_callback, optional: true
  belongs_to :source, polymorphic: true, optional: true
  
  enum status: {
    draft: 'draft',
    sent: 'sent',
    viewed: 'viewed',
    paid: 'paid',
    cancelled: 'cancelled',
    refunded: 'refunded'
  }
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :customer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :description, presence: true
  
  before_validation :set_business_defaults, on: :create
  
  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: ['draft', 'sent', 'viewed']) }
  
  def customer
    return agent_callback.customer if agent_callback&.customer
    Customer.find_by(email: customer_email) || Customer.find_by(phone_number: customer_phone)
  end
  
  def formatted_amount
    "$#{amount.to_f}"
  end
  
  def overdue?
    due_date.present? && due_date < Date.current && !paid?
  end
  
  def paypal_invoice_link
    paypal_invoice_url
  end
  
  def billing_address
    return nil unless billing_address_line1.present?
    
    address_parts = [
      billing_address_line1,
      billing_address_line2,
      billing_city,
      billing_state,
      billing_postal_code,
      billing_country
    ].compact.reject(&:blank?)
    
    address_parts.join(', ')
  end
  
  def shipping_address
    return nil unless shipping_address_line1.present?
    
    address_parts = [
      shipping_address_line1,
      shipping_address_line2,
      shipping_city,
      shipping_state,
      shipping_postal_code,
      shipping_country
    ].compact.reject(&:blank?)
    
    address_parts.join(', ')
  end
  
  # Invoice type helpers
  def invoice_type
    return 'pre_order' if source_type == 'AgentCallback'
    return 'order_payment' if source_type == 'Order'
    'standalone'
  end
  
  def pre_order_invoice?
    source_type == 'AgentCallback'
  end
  
  def order_payment_invoice?
    source_type == 'Order'
  end
  
  def standalone_invoice?
    source_type.blank?
  end
  
  def source_callback
    source if source_type == 'AgentCallback'
  end
  
  def source_order
    source if source_type == 'Order'
  end
  
  def can_create_order?
    pre_order_invoice? && paid? && !order_already_created?
  end
  
  def order_already_created?
    return false unless pre_order_invoice?
    # Check if an order was already created from this invoice's callback
    source_callback&.status == 'sale' || 
    Order.exists?(agent_callback: source_callback)
  end
  
  def type_display
    case invoice_type
    when 'pre_order'
      '🔄 Pre-Order'
    when 'order_payment'
      '📦 Order Payment'
    else
      '💰 Standalone'
    end
  end
  
  def type_description
    case invoice_type
    when 'pre_order'
      'From callback - will create order when paid'
    when 'order_payment'
      'Payment for existing order'
    else
      'Manual invoice'
    end
  end
  
  def set_business_defaults
    self.business_name ||= 'AutoXpress'
    self.business_email ||= 'khan@autoxpress.us'
  end
end