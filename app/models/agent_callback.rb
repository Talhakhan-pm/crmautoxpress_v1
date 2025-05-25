class AgentCallback < ApplicationRecord
  belongs_to :user
  has_many :activities, as: :trackable, dependent: :destroy
  
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

  include Trackable
  
  after_create_commit :find_or_create_customer
  after_create_commit { broadcast_prepend_to "callbacks", target: "callbacks" }
  after_update_commit { broadcast_replace_to "callbacks" }
  after_destroy_commit { broadcast_remove_to "callbacks" }
  
  # Dashboard broadcasts - inline to ensure they execute
  after_create_commit { broadcast_dashboard_metrics }
  after_update_commit { broadcast_dashboard_metrics }
  after_destroy_commit { broadcast_dashboard_metrics }
  
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
    
    customer = Customer.find_or_create_by(phone_number: phone_number) do |c|
      c.name = customer_name
      c.source_campaign = 'callback'
      Rails.logger.info "Created new customer: #{c.name}"
    end
    
    # Update customer with Google Ads data if this callback has session data
    if defined?(Current) && Current.respond_to?(:session) && Current.session
      google_ads_data = Current.session[:google_ads_data]
      if google_ads_data && customer.gclid.blank?
        customer.update(
          gclid: google_ads_data[:gclid],
          utm_source: google_ads_data[:utm_source],
          utm_campaign: google_ads_data[:utm_campaign],
          source_campaign: 'google_ads'
        )
        Rails.logger.info "Updated customer with Google Ads data: #{google_ads_data}"
      end
    end
    
    Rails.logger.info "Customer found/created: #{customer.id} - #{customer.name}"
    
    # Customer is linked via phone_number - no need for additional foreign key
  rescue => e
    Rails.logger.error "Customer auto-creation failed: #{e.message}"
  end
end
