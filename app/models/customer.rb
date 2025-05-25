class Customer < ApplicationRecord
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
  
  after_create_commit { broadcast_prepend_to "customers", target: "customers" }
  after_update_commit { broadcast_replace_to "customers" }
  after_destroy_commit { broadcast_remove_to "customers" }
  
  after_create_commit { broadcast_dashboard_metrics }
  after_update_commit { broadcast_dashboard_metrics }
  after_destroy_commit { broadcast_dashboard_metrics }
  
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
