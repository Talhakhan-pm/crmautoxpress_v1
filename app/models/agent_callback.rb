class AgentCallback < ApplicationRecord
  belongs_to :user
  has_many :activities, as: :trackable, dependent: :destroy
  has_many :communications, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :source_invoices, as: :source, class_name: 'Invoice', dependent: :destroy
  
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
  
  # ============================================================================
  # ACTION-FOCUSED LAYOUT METHODS
  # ============================================================================
  
  # Call tracking using existing activities
  def call_attempts_count
    @call_attempts_count ||= activities.where(action: ['call_initiated', 'call_failed']).count
  end
  
  def successful_call_attempts_count
    @successful_call_attempts_count ||= activities.where(action: 'call_initiated').count
  end
  
  def failed_call_attempts_count
    @failed_call_attempts_count ||= activities.where(action: 'call_failed').count
  end
  
  def last_call_attempt
    activities.where(action: ['call_initiated', 'call_failed']).order(created_at: :desc).first
  end
  
  # Smart priority calculation
  def calculate_smart_priority
    return 'high' if should_be_high_priority?
    return 'low' if should_be_low_priority?
    'medium'
  end
  
  def auto_update_priority!
    new_priority = calculate_smart_priority
    if priority_level != new_priority
      update_column(:priority_level, new_priority)
      broadcast_priority_change
    end
  end
  
  # Smart next action suggestions with time-based context
  def suggest_next_action
    # Immediate actions based on status
    return "🎯 Complete sale - create order & process payment" if status == 'sale'
    return "💰 Create order from paid invoice - ready to proceed" if ready_for_order_creation?
    return "📋 Follow up on pricing quote sent" if has_invoices? && !paid_invoices.any?
    
    # Time-sensitive follow-ups
    if follow_up_date
      case follow_up_status
      when 'overdue'
        return "⚠️ URGENT: Overdue follow-up call"
      when 'today'
        return "📞 Call today as scheduled"
      when 'tomorrow'
        return "📅 Prepare for tomorrow's call"
      end
    end
    
    # Call-attempt based actions
    case call_attempts_count
    when 0
      "📞 Make initial contact call"
    when 1
      "🔄 Second attempt - try different time"
    when 2
      "📧 Third attempt or send email first"
    when 3..5
      "📩 Send quote via email - multiple call attempts"
    else
      "📝 Review strategy - many attempts made"
    end
  end
  
  def auto_update_next_action!
    suggested_action = suggest_next_action
    if next_action != suggested_action
      update_column(:next_action, suggested_action)
    end
  end
  
  # Contact date management
  def update_last_contact_date!
    update_column(:last_contact_date, Time.current)
    auto_update_priority!
    auto_update_next_action!
  end
  
  # Quick action methods
  def mark_as_called!(current_user = nil)
    create_activity(
      action: 'call_initiated',
      details: "Agent marked as called via quick action",
      user: current_user
    )
    update_last_contact_date!
    broadcast_card_update
  end
  
  def mark_as_no_answer!(current_user = nil)
    create_activity(
      action: 'call_failed',
      details: "No answer - quick action",
      user: current_user
    )
    
    # Smart follow-up timing based on attempt count
    follow_up_delay = case call_attempts_count
    when 1
      4.hours # Try again same day
    when 2 
      1.day # Try tomorrow
    else
      2.days # Give more space after multiple attempts
    end
    
    update!(
      status: 'follow_up',
      follow_up_date: follow_up_delay.from_now.to_date,
      last_contact_date: Time.current,
      next_action: "📞 Call back - no answer (attempt ##{call_attempts_count + 1})"
    )
    auto_update_priority!
    broadcast_card_update
  end
  
  def mark_as_interested!
    update!(
      status: 'follow_up',
      follow_up_date: 1.day.from_now.to_date,
      last_contact_date: Time.current,
      next_action: "💡 Send pricing quote - customer showed interest",
      priority_level: 'high'
    )
    auto_update_priority!
    broadcast_card_update
  end
  
  def mark_as_later!
    update!(
      status: 'follow_up',
      follow_up_date: 1.week.from_now.to_date,
      last_contact_date: Time.current,
      next_action: "⏰ Call back as requested - customer asked for later contact"
    )
    auto_update_priority!
    broadcast_card_update
  end
  
  def mark_as_sale!
    update!(
      status: 'sale',
      last_contact_date: Time.current,
      next_action: "Create order and process sale"
    )
    auto_update_priority!
    broadcast_card_update
  end
  
  def mark_as_not_interested!
    update!(
      status: 'not_interested',
      last_contact_date: Time.current,
      next_action: "Lead closed - not interested"
    )
    auto_update_priority!
    broadcast_card_update
  end
  
  # Priority level display helpers
  def priority_badge_class
    case priority_level
    when 'high'
      'badge-danger'
    when 'low' 
      'badge-secondary'
    else
      'badge-warning'
    end
  end
  
  def priority_icon
    case priority_level
    when 'high'
      '🔥'
    when 'low'
      '📊'
    else
      '⚡'
    end
  end
  
  def priority_display
    "#{priority_icon} #{(priority_level || 'medium').upcase}"
  end
  
  # Follow-up helpers
  def follow_up_status
    return nil unless follow_up_date
    
    if follow_up_date < Date.current
      'overdue'
    elsif follow_up_date == Date.current
      'today'
    elsif follow_up_date == Date.current + 1.day
      'tomorrow'
    else
      'upcoming'
    end
  end
  
  def follow_up_display
    return "No follow-up set" unless follow_up_date
    
    case follow_up_status
    when 'overdue'
      "⚠️ Overdue: #{follow_up_date.strftime('%b %d')}"
    when 'today'
      "🎯 Today"
    when 'tomorrow'
      "📅 Tomorrow"
    else
      "📅 #{follow_up_date.strftime('%b %d')}"
    end
  end
  
  # Real-time broadcast helpers
  def broadcast_card_update
    broadcast_replace_to "callbacks", 
                        target: ActionView::RecordIdentifier.dom_id(self, :card),
                        partial: "callbacks/dashboard_card", 
                        locals: { callback: self }
  end
  
  def broadcast_priority_change
    # Could add specific priority change broadcasts if needed
    broadcast_card_update
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
  
  # Invoice-related methods
  def has_invoices?
    source_invoices.any?
  end
  
  def paid_invoices
    source_invoices.paid
  end
  
  def pending_invoices
    source_invoices.where(status: ['draft', 'sent', 'viewed'])
  end
  
  def latest_invoice
    source_invoices.order(created_at: :desc).first
  end
  
  def ready_for_order_creation?
    paid_invoices.any? && status != 'sale'
  end
  
  def can_create_invoice?
    # Can create invoice if no pending invoices exist
    !pending_invoices.any?
  end
  
  # Smart priority logic
  def should_be_high_priority?
    # Overdue follow-ups
    return true if follow_up_date && follow_up_date < Date.current
    
    # Callbacks older than 3 days with no calls
    return true if created_at < 3.days.ago && call_attempts_count == 0
    
    # Multiple call attempts with no sale
    return true if call_attempts_count >= 3 && status != 'sale'
    
    # Has paid invoice but no order created
    return true if ready_for_order_creation?
    
    false
  end
  
  def should_be_low_priority?
    # Already converted to sale
    return true if status == 'sale'
    
    # Not interested
    return true if status == 'not_interested'
    
    # Already purchased elsewhere
    return true if status == 'already_purchased'
    
    false
  end
  
  # Model-level validations (no database constraints)
  validates :priority_level, inclusion: { in: ['low', 'medium', 'high'] }, allow_nil: true
  validates :next_action, length: { maximum: 500 }, allow_blank: true
  
  # Auto-update hooks
  after_create :initialize_action_focused_fields
  after_update :auto_update_priority_on_status_change, if: :saved_change_to_status?
  after_update :auto_update_next_action_on_status_change, if: :saved_change_to_status?
  
  def auto_update_priority_on_status_change
    auto_update_priority!
  end
  
  def auto_update_next_action_on_status_change
    auto_update_next_action!
  end
  
  def initialize_action_focused_fields
    self.update_columns(
      priority_level: calculate_smart_priority,
      next_action: suggest_next_action
    )
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
