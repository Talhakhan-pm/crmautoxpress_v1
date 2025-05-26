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
    product_not_found: 0,
    item_doesnt_fit: 1,
    dispatch_cancelled: 2,
    shipping_failed: 3,
    customer_cancelled: 4,
    quality_issue: 5,
    payment_failed: 6,
    address_invalid: 7
  }

  validates :charge, :refund_amount, presence: true, numericality: { greater_than: 0 }
  validates :customer_name, :customer_email, :agent_name, presence: true
  validates :refund_stage, :refund_reason, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(refund_stage: :pending_review) }

  def refund_percentage
    return 0 if charge.zero?
    ((refund_amount / charge) * 100).round(2)
  end

  def full_refund?
    refund_amount >= charge
  end
end
