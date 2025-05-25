class Customer < ApplicationRecord
  include ActionView::RecordIdentifier
  
  has_many :agent_callbacks, foreign_key: :phone_number, primary_key: :phone_number
  has_many :activities, as: :trackable, dependent: :destroy
  
  enum status: {
    active: 0,
    inactive: 1,
    blacklisted: 2
  }

  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  include Trackable
  
  # Turbo Stream broadcasts - with seeding guard
  after_create_commit { broadcast_customer_created unless Rails.env.test? || defined?(Rails::Console) }
  after_update_commit { broadcast_customer_updated unless Rails.env.test? || defined?(Rails::Console) }
  after_destroy_commit { broadcast_customer_destroyed unless Rails.env.test? || defined?(Rails::Console) }
  
  # Dashboard broadcasts - commented out for now
  # after_create_commit { broadcast_dashboard_metrics }
  # after_update_commit { broadcast_dashboard_metrics }
  # after_destroy_commit { broadcast_dashboard_metrics }
  
  scope :with_callbacks, -> { joins(:agent_callbacks).distinct }
  scope :google_ads, -> { where.not(gclid: [nil, '']) }
  
  def full_name
    name
  end
  
  def callback_count
    agent_callbacks.count
  end
  
  def last_callback
    agent_callbacks.order(created_at: :desc).first
  end
  
  private
  
  def broadcast_customer_created
    Rails.logger.info "=== CUSTOMER BROADCAST: CREATED ==="
    Rails.logger.info "Broadcasting customer creation for: #{name} (#{phone_number})"
    
    broadcast_prepend_to "customers", 
                        target: "customers", 
                        partial: "customers/customer", 
                        locals: { customer: self }
                        
    Rails.logger.info "=== CUSTOMER BROADCAST: CREATED SENT ==="
  end
  
  def broadcast_customer_updated
    Rails.logger.info "=== CUSTOMER BROADCAST: UPDATED ==="
    
    broadcast_replace_to "customers", 
                        target: dom_id(self), 
                        partial: "customers/customer", 
                        locals: { customer: self }
                        
    Rails.logger.info "=== CUSTOMER BROADCAST: UPDATED SENT ==="
  end
  
  def broadcast_customer_destroyed
    Rails.logger.info "=== CUSTOMER BROADCAST: DESTROYED ==="
    
    broadcast_remove_to "customers", target: dom_id(self)
    
    Rails.logger.info "=== CUSTOMER BROADCAST: DESTROYED SENT ==="
  end
  
  def broadcast_dashboard_metrics
    Rails.logger.info "=== CUSTOMER DASHBOARD METRICS BROADCAST ==="
    stats = calculate_customer_stats
    
    broadcast_replace_to "dashboard", 
                        target: "customer-metrics", 
                        partial: "dashboard/customer_metrics", 
                        locals: { stats: stats }
  end
  
  def calculate_customer_stats
    {
      total_customers: Customer.count,
      active_customers: Customer.active.count,
      google_ads_customers: Customer.google_ads.count,
      customers_with_callbacks: Customer.with_callbacks.count
    }
  end
end
