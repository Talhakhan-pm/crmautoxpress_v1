class AgentCallback < ApplicationRecord
  belongs_to :user
  has_many :activities, as: :trackable, dependent: :destroy
  
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
end
