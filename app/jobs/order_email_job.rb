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
        mail = OrderMailer.confirmation(order)
        if mail.present?
          mail.deliver_now
          log_email_success(order, 'confirmation')
        else
          Rails.logger.warn "OrderEmailJob: Confirmation email skipped for order ##{order.order_number} (validation failed)"
        end
        
      when 'shipping_notification'
        mail = OrderMailer.shipping_notification(order)
        if mail.present?
          mail.deliver_now
          log_email_success(order, 'shipping_notification')
        else
          Rails.logger.warn "OrderEmailJob: Shipping email skipped for order ##{order.order_number} (validation failed)"
        end
        
      when 'follow_up'
        mail = OrderMailer.follow_up(order)
        if mail.present?
          # Wait specified delay before sending follow-up
          delay = options[:delay_days] || 3
          if order.created_at <= delay.days.ago
            mail.deliver_now
            log_email_success(order, 'follow_up')
          end
        else
          Rails.logger.warn "OrderEmailJob: Follow-up email skipped for order ##{order.order_number} (validation failed)"
        end
        
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