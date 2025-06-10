class Invoice < ApplicationRecord
  belongs_to :agent_callback, optional: true
  
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
end