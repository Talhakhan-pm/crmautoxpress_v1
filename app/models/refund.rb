class Refund < ApplicationRecord
  belongs_to :order
  belongs_to :dispatch
  belongs_to :processing_agent, class_name: 'User'

  enum refund_stage: {
    pending_review: 0,
    approved: 1,
    processing: 2,
    completed: 3,
    rejected: 4
  }

  enum refund_reason: {
    product_not_found: 0,        # Processing agent couldn't fulfill
    item_doesnt_fit: 1,         # Wrong part shipped
    dispatch_cancelled: 2,       # Agent cancelled before shipping
    shipping_failed: 3,         # Carrier issues
    customer_cancelled: 4,      # Customer requested cancellation
    quality_issue: 5,           # Product damaged/defective
    payment_failed: 6,          # Payment processing issues
    address_invalid: 7,         # Shipping address problems
    price_discrepancy: 8        # Sold below target price
  }

  validates :charge, :refund_amount, presence: true, numericality: { greater_than: 0 }
  validates :customer_name, :customer_email, :agent_name, presence: true
  validates :refund_stage, :refund_reason, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(refund_stage: :pending_review) }
  scope :by_reason, ->(reason) { where(refund_reason: reason) }

  def refund_percentage
    return 0 if charge.zero?
    ((refund_amount / charge) * 100).round(2)
  end

  def full_refund?
    refund_amount >= charge
  end

  def reason_display
    return 'Unknown Reason' if refund_reason.blank?
    
    case refund_reason
    when 'product_not_found' then 'Product Not Available'
    when 'item_doesnt_fit' then 'Wrong Part Shipped'
    when 'dispatch_cancelled' then 'Dispatch Cancelled'
    when 'shipping_failed' then 'Shipping Issues'
    when 'customer_cancelled' then 'Customer Cancellation'
    when 'quality_issue' then 'Product Defective'
    when 'payment_failed' then 'Payment Failed'
    when 'address_invalid' then 'Invalid Address'
    when 'price_discrepancy' then 'Price Issue'
    else refund_reason.humanize
    end
  end

  def stage_color
    return 'secondary' if refund_stage.blank?
    
    case refund_stage
    when 'pending_review' then 'warning'
    when 'approved' then 'info'
    when 'processing' then 'primary'
    when 'completed' then 'success'
    when 'rejected' then 'danger'
    else 'secondary'
    end
  end

  def stage_display
    return 'Unknown' if refund_stage.blank?
    refund_stage.humanize
  end

  def replacement_eligible?
    ['item_doesnt_fit', 'quality_issue', 'shipping_failed'].include?(refund_reason)
  end
end
