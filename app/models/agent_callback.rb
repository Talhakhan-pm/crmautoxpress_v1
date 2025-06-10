class AgentCallback < ApplicationRecord
  belongs_to :user
  has_many :activities, as: :trackable, dependent: :destroy
  has_many :communications, dependent: :destroy
  has_many :invoices, dependent: :destroy
  
  def customer
    @customer ||= Customer.find_by(phone_number: phone_number)
  end
  
  enum status: {
    pending: 0,
    not_interested: 1,
    already_purchased: 2,
    sale: 3,
    payment_link: 4,
    follow_up: 5
  }

  validates :customer_name, presence: true
  validates :phone_number, presence: true
  validates :product, presence: true
  validates :status, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  
  # Dashboard-specific scopes (database agnostic)
  scope :with_communication_stats, -> {
    left_joins(:communications)
      .select('agent_callbacks.*, COUNT(communications.id) as communications_count')
      .group('agent_callbacks.id')
  }
  
  scope :recent_activity_first, -> {
    left_joins(:communications)
      .group('agent_callbacks.id')
      .order(Arel.sql('MAX(COALESCE(communications.created_at, agent_callbacks.created_at)) DESC'))
  }

  include Trackable
  
  after_create_commit :find_or_create_customer
  after_create_commit :extract_and_create_product, unless: :auto_generated_from_order?
  
  # Turbo Stream broadcasts - with seeding guard
  after_create_commit { broadcast_prepend_to "callbacks", target: "callbacks" unless Rails.env.test? || defined?(Rails::Console) }
  after_update_commit { broadcast_replace_to "callbacks" unless Rails.env.test? || defined?(Rails::Console) }
  after_destroy_commit { broadcast_remove_to "callbacks" unless Rails.env.test? || defined?(Rails::Console) }
  
  # Dashboard broadcasts - with seeding guard
  after_create_commit { broadcast_dashboard_metrics unless Rails.env.test? || defined?(Rails::Console) }
  after_update_commit { broadcast_dashboard_metrics unless Rails.env.test? || defined?(Rails::Console) }
  after_destroy_commit { broadcast_dashboard_metrics unless Rails.env.test? || defined?(Rails::Console) }
  
  def auto_generated_from_order?
    notes&.include?("Auto-generated from Order")
  end
  
  def agent
    user&.email
  end
  
  # Dashboard helper methods
  def latest_communication
    @latest_communication ||= communications.includes(:user).order(created_at: :desc).first
  end
  
  def communications_count
    if has_attribute?(:communications_count)
      read_attribute(:communications_count) || 0
    else
      communications.count
    end
  end
  
  def unread_communications_for(user)
    # Count communications since user last viewed this callback
    last_view = activities.where(user: user, action: 'viewed').order(created_at: :desc).first
    if last_view
      communications.where('created_at > ?', last_view.created_at).count
    else
      communications.count
    end
  end
  
  def team_members
    @team_members ||= User.joins(:activities)
                         .where(activities: { trackable: self })
                         .distinct
                         .limit(5)
  end
  
  def has_recent_activity?
    latest_communication&.created_at&.> 1.day.ago
  end
  
  private
  
  def broadcast_dashboard_metrics
    Rails.logger.info "=== DASHBOARD METRICS BROADCAST TRIGGERED ==="
    stats = calculate_fresh_stats
    Rails.logger.info "Stats: #{stats}"
    
    broadcast_replace_to "dashboard", 
                        target: "dashboard-metrics", 
                        partial: "dashboard/metrics", 
                        locals: { stats: stats }
                        
    Rails.logger.info "=== DASHBOARD METRICS BROADCAST SENT ==="
  end
  
  def calculate_fresh_stats
    total_count = AgentCallback.count
    sales_count = AgentCallback.where(status: ['sale', 'payment_link']).count
    
    {
      total_leads: total_count,
      pending_leads: AgentCallback.pending.count,
      sales_closed: sales_count,
      conversion_rate: total_count > 0 ? ((sales_count.to_f / total_count) * 100).round(1) : 0,
      follow_ups_due: AgentCallback.follow_up.where(follow_up_date: Date.current..3.days.from_now).count
    }
  end
  
  def find_or_create_customer
    return unless phone_number.present? && customer_name.present?
    
    Rails.logger.info "=== AUTO-CREATING CUSTOMER FROM CALLBACK ==="
    Rails.logger.info "Phone: #{phone_number}, Name: #{customer_name}"
    
    customer_created = false
    customer = Customer.find_by(phone_number: phone_number)
    
    unless customer
      customer = Customer.create!(
        phone_number: phone_number,
        name: customer_name,
        source_campaign: 'callback'
      )
      customer_created = true
      Rails.logger.info "Created new customer: #{customer.name}"
    end
    
    Rails.logger.info "Customer found/created: #{customer.id} - #{customer.name}"
    Rails.logger.info "Customer creation triggered broadcasts: #{customer_created}"
    
    customer
  rescue => e
    Rails.logger.error "Customer auto-creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
  
  def extract_and_create_product
    return unless product.present?
    
    Rails.logger.info "=== AUTO-EXTRACTING PRODUCT FROM CALLBACK ==="
    Rails.logger.info "Product text: #{product}"
    
    # Simple extraction logic - create product from callback text
    product_name = product.strip
    
    # Check if product already exists (by name similarity)
    existing_product = Product.where(Product.arel_table[:name].matches("%#{product_name}%")).first
    
    unless existing_product
      # Generate a simple part number from the product name
      part_number = generate_part_number(product_name)
      
      # Try to guess category from product name
      category = guess_category_from_name(product_name)
      
      new_product = Product.create!(
        name: product_name,
        part_number: part_number,
        category: category,
        description: "Auto-extracted from callback ##{id}",
        vendor_cost: 0.01, # Placeholder values
        selling_price: 0.01,
        source: 'callback',
        status: 'active'
      )
      
      Rails.logger.info "Created new product: #{new_product.name} (#{new_product.part_number})"
    else
      Rails.logger.info "Product already exists: #{existing_product.name}"
    end
    
  rescue => e
    Rails.logger.error "Product auto-extraction failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
  
  private
  
  def generate_part_number(name)
    # Simple part number generation
    prefix = name.split.first&.upcase&.first(3) || "GEN"
    timestamp = Time.current.strftime("%m%d%H%M")
    "#{prefix}-#{timestamp}"
  end
  
  def guess_category_from_name(name)
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
end
