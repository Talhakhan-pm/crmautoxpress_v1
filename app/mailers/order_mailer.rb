class OrderMailer < ApplicationMailer
  default from: 'orders@autoxpress.com'

  def confirmation(order)
    @order = order
    @customer = order.customer || build_customer_from_order(order)
    @agent = order.agent
    
    # Validate required data
    return nil unless order.customer_email.present?
    
    # Track email activity
    create_email_activity(order, 'confirmation_email_sent')
    
    mail(
      to: order.customer_email,
      cc: get_agent_cc(order),
      subject: "Order Confirmation ##{order.order_number} - AutoXpress"
    )
  end

  def shipping_notification(order)
    @order = order
    @customer = order.customer || build_customer_from_order(order)
    @dispatch = order.dispatch
    
    # Validate required data
    return nil unless order.customer_email.present? && order.dispatch.present?
    
    # Track email activity
    create_email_activity(order, 'shipping_email_sent')
    
    mail(
      to: order.customer_email,
      cc: get_agent_cc(order),
      subject: "Your Order ##{order.order_number} Has Shipped - AutoXpress"
    )
  end

  def follow_up(order)
    @order = order
    @customer = order.customer || build_customer_from_order(order)
    @agent = order.agent
    
    # Validate required data
    return nil unless order.customer_email.present?
    
    # Track email activity
    create_email_activity(order, 'follow_up_email_sent')
    
    mail(
      to: order.customer_email,
      cc: get_agent_cc(order),
      subject: "How's Your New #{order.product_name}? - AutoXpress"
    )
  end

  private

  def get_agent_cc(order)
    return nil unless order.agent&.email.present?
    order.agent.email
  rescue => e
    Rails.logger.error "Failed to get agent CC for order ##{order.order_number}: #{e.message}"
    nil
  end

  def build_customer_from_order(order)
    OpenStruct.new(
      name: order.customer_name,
      email: order.customer_email,
      phone: order.customer_phone,
      address: order.customer_address
    )
  end

  def create_email_activity(order, action_type)
    Activity.create!(
      trackable: order,
      user: order.agent,
      action: action_type,
      field_changed: 'email_communication',
      new_value: order.customer_email,
      details: "Email sent to #{order.customer_name} (#{order.customer_email})"
    )
  rescue => e
    Rails.logger.error "Failed to create email activity: #{e.message}"
  end
end