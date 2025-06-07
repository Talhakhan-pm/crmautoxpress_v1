class OrderEmailJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(order_id, email_type, options = {})
    order = Order.find(order_id)
    
    # Validate email recipient
    unless order.customer_email.present?
      Rails.logger.error "OrderEmailJob: No customer email for order ##{order.order_number}"
      return
    end
    
    begin
      case email_type.to_s
      when 'confirmation'
        OrderMailer.confirmation(order).deliver_now
        log_email_success(order, 'confirmation')
        
      when 'shipping_notification'
        OrderMailer.shipping_notification(order).deliver_now
        log_email_success(order, 'shipping_notification')
        
      when 'follow_up'
        # Wait specified delay before sending follow-up
        delay = options[:delay_days] || 3
        OrderMailer.follow_up(order).deliver_now if order.created_at <= delay.days.ago
        log_email_success(order, 'follow_up')
        
      else
        Rails.logger.error "OrderEmailJob: Unknown email type '#{email_type}'"
      end
      
    rescue => e
      Rails.logger.error "OrderEmailJob failed for order ##{order.order_number}: #{e.message}"
      log_email_failure(order, email_type, e.message)
      raise e
    end
  end

  private

  def log_email_success(order, email_type)
    Rails.logger.info "✅ Email sent successfully: #{email_type} for order ##{order.order_number} to #{order.customer_email}"
  end

  def log_email_failure(order, email_type, error_message)
    Rails.logger.error "❌ Email failed: #{email_type} for order ##{order.order_number} - #{error_message}"
    
    # Create failure activity log
    Activity.create!(
      trackable: order,
      user: order.agent,
      action: "#{email_type}_email_failed",
      field_changed: 'email_communication',
      old_value: order.customer_email,
      new_value: 'failed',
      details: "Email delivery failed: #{error_message}"
    )
  end
end