class Supplier < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :dispatches, through: :orders
  has_many :activities, as: :trackable, dependent: :destroy
  
  # Many-to-many relationship with products
  has_many :supplier_products, dependent: :destroy
  has_many :products, through: :supplier_products
  
  validates :name, presence: true
  
  include Trackable
  
  # Turbo Stream broadcasts
  after_create_commit { broadcast_supplier_created unless Rails.env.test? || defined?(Rails::Console) }
  after_update_commit { broadcast_supplier_updated unless Rails.env.test? || defined?(Rails::Console) }
  after_destroy_commit { broadcast_supplier_destroyed unless Rails.env.test? || defined?(Rails::Console) }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_source, ->(source) { where(source: source) }
  scope :with_orders, -> { joins(:orders).distinct }
  
  def update_total_orders!
    update!(total_orders: orders.count)
  end
  
  def average_quality_rating
    ratings = orders.where.not(quality_rating: nil).pluck(:quality_rating)
    return 0 if ratings.empty?
    (ratings.sum.to_f / ratings.count).round(2)
  end
  
  def on_time_delivery_rate
    completed_orders = orders.joins(:dispatch).where(dispatches: { dispatch_status: 'completed' })
    return 0 if completed_orders.empty?
    
    on_time = completed_orders.where('actual_delivery_date <= estimated_delivery_date').count
    ((on_time.to_f / completed_orders.count) * 100).round(1)
  end
  
  # Product relationship methods
  def products_count
    products.count
  end
  
  def preferred_products
    supplier_products.preferred.includes(:product)
  end
  
  def products_by_category(category)
    products.where(category: category)
  end
  
  def best_deals
    supplier_products.select { |sp| sp.is_better_deal? }
  end
  
  def add_product(product, cost: nil, part_number: nil, lead_time: nil, preferred: false)
    supplier_products.find_or_create_by(product: product) do |sp|
      sp.supplier_cost = cost
      sp.supplier_part_number = part_number
      sp.lead_time_days = lead_time
      sp.preferred_supplier = preferred
      sp.last_quoted_date = Date.current
    end
  end
  
  private
  
  def broadcast_supplier_created
    Rails.logger.info "=== SUPPLIER BROADCAST: CREATED ==="
    # Add broadcast logic here if needed
  end
  
  def broadcast_supplier_updated
    Rails.logger.info "=== SUPPLIER BROADCAST: UPDATED ==="
    # Add broadcast logic here if needed
  end
  
  def broadcast_supplier_destroyed
    Rails.logger.info "=== SUPPLIER BROADCAST: DESTROYED ==="
    # Add broadcast logic here if needed
  end
end
