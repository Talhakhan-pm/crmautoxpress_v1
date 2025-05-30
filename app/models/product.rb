class Product < ApplicationRecord
  include ActionView::RecordIdentifier
  
  has_many :activities, as: :trackable, dependent: :destroy
  
  # Many-to-many relationship with suppliers
  has_many :supplier_products, dependent: :destroy
  has_many :suppliers, through: :supplier_products
  
  enum status: {
    active: 0,
    discontinued: 1,
    backordered: 2,
    out_of_stock: 3
  }

  validates :name, presence: true
  validates :part_number, presence: true, uniqueness: true
  validates :category, presence: true
  validates :vendor_cost, presence: true, numericality: { greater_than: 0 }
  validates :selling_price, presence: true, numericality: { greater_than: 0 }

  include Trackable
  
  # Turbo Stream broadcasts - with seeding guard
  after_create_commit { broadcast_product_created unless Rails.env.test? || defined?(Rails::Console) }
  after_update_commit { broadcast_product_updated unless Rails.env.test? || defined?(Rails::Console) }
  after_destroy_commit { broadcast_product_destroyed unless Rails.env.test? || defined?(Rails::Console) }
  
  
  scope :by_category, ->(category) { where(category: category) }
  scope :by_source, ->(source) { where(source: source) }
  scope :in_stock, -> { where.not(status: ['discontinued', 'out_of_stock']) }
  scope :search, ->(term) { where("name LIKE ? OR part_number LIKE ? OR description LIKE ?", "%#{term}%", "%#{term}%", "%#{term}%") }
  
  def vehicle_compatibility_list
    return [] if vehicle_compatibility.blank?
    JSON.parse(vehicle_compatibility) rescue []
  end
  
  def vehicle_compatibility_list=(list)
    self.vehicle_compatibility = list.to_json
  end
  
  def profit_margin
    return 0 if vendor_cost.zero? || selling_price.zero?
    ((selling_price - vendor_cost) / selling_price * 100).round(2)
  end
  
  def markup_percentage
    return 0 if vendor_cost.zero?
    ((selling_price - vendor_cost) / vendor_cost * 100).round(2)
  end
  
  def display_category
    category.humanize
  end
  
  private
  
  def broadcast_product_created
    Rails.logger.info "=== PRODUCT BROADCAST: CREATED ==="
    Rails.logger.info "Broadcasting product creation for: #{name} (#{part_number})"
    
    broadcast_prepend_to "products", 
                        target: "products", 
                        partial: "products/product", 
                        locals: { product: self }
                        
    Rails.logger.info "=== PRODUCT BROADCAST: CREATED SENT ==="
  end
  
  def broadcast_product_updated
    Rails.logger.info "=== PRODUCT BROADCAST: UPDATED ==="
    
    broadcast_replace_to "products", 
                        target: dom_id(self), 
                        partial: "products/product", 
                        locals: { product: self }
                        
    Rails.logger.info "=== PRODUCT BROADCAST: UPDATED SENT ==="
  end
  
  def broadcast_product_destroyed
    Rails.logger.info "=== PRODUCT BROADCAST: DESTROYED ==="
    
    broadcast_remove_to "products", target: dom_id(self)
    
    Rails.logger.info "=== PRODUCT BROADCAST: DESTROYED SENT ==="
  end
  
end
