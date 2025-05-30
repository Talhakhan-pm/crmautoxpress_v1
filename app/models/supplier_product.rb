class SupplierProduct < ApplicationRecord
  belongs_to :supplier
  belongs_to :product
  
  validates :supplier_cost, numericality: { greater_than: 0 }, allow_blank: true
  validates :lead_time_days, numericality: { greater_than: 0 }, allow_blank: true
  
  scope :preferred, -> { where(preferred_supplier: true) }
  scope :recent_quotes, -> { order(last_quoted_date: :desc) }
  scope :by_cost, -> { order(:supplier_cost) }
  
  def profit_margin_vs_product
    return 0 unless supplier_cost.present? && product.selling_price.present?
    ((product.selling_price - supplier_cost) / product.selling_price * 100).round(2)
  end
  
  def cost_difference_vs_product
    return 0 unless supplier_cost.present? && product.vendor_cost.present?
    supplier_cost - product.vendor_cost
  end
  
  def is_better_deal?
    return false unless supplier_cost.present? && product.vendor_cost.present?
    supplier_cost < product.vendor_cost
  end
  
  def last_quoted_days_ago
    return nil unless last_quoted_date.present?
    (Date.current - last_quoted_date).to_i
  end
end
