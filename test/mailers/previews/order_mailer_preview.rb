# Preview all emails at http://localhost:3000/rails/mailers/order_mailer
class OrderMailerPreview < ActionMailer::Preview
  
  # Preview this email at http://localhost:3000/rails/mailers/order_mailer/confirmation
  def confirmation
    order = Order.first || create_sample_order
    OrderMailer.confirmation(order)
  end

  # Preview this email at http://localhost:3000/rails/mailers/order_mailer/shipping_notification
  def shipping_notification
    order = Order.joins(:dispatch).first || create_sample_order_with_dispatch
    OrderMailer.shipping_notification(order)
  end

  # Preview this email at http://localhost:3000/rails/mailer/order_mailer/follow_up
  def follow_up
    order = Order.where(order_status: 'delivered').first || create_sample_delivered_order
    OrderMailer.follow_up(order)
  end

  private

  def create_sample_order
    user = User.first || User.create!(
      email: 'agent@autoxpress.com',
      password: 'password123'
    )

    Order.create!(
      order_number: "AX#{Date.current.strftime('%Y%m%d')}001",
      order_date: Time.current,
      customer_name: "John Smith",
      customer_email: "john.smith@email.com",
      customer_phone: "(555) 123-4567",
      customer_address: "123 Main St, Anytown, ST 12345",
      product_name: "Premium Brake Pads - Ceramic",
      car_year: 2020,
      car_make_model: "Honda Civic",
      product_price: 149.99,
      tax_amount: 12.00,
      shipping_cost: 15.00,
      total_amount: 176.99,
      order_status: 'confirmed',
      priority: 'standard',
      source_channel: 'phone',
      agent: user,
      estimated_delivery: 5.days.from_now.to_date,
      warranty_period_days: 12,
      warranty_terms: "12-month warranty against manufacturing defects"
    )
  end

  def create_sample_order_with_dispatch
    order = create_sample_order
    order.create_dispatch!(
      order_number: order.order_number,
      customer_name: order.customer_name,
      customer_address: order.customer_address,
      product_name: order.product_name,
      processing_agent: order.agent,
      product_cost: order.product_price,
      total_cost: order.total_amount,
      tracking_number: "1Z999AA1234567890",
      tracking_link: "https://www.ups.com/track?tracknum=1Z999AA1234567890",
      dispatch_status: 'shipped',
      shipment_status: 'in_transit'
    )
    order
  end

  def create_sample_delivered_order
    order = create_sample_order_with_dispatch
    order.update!(order_status: 'delivered')
    order.dispatch.update!(
      dispatch_status: 'completed',
      shipment_status: 'delivered'
    )
    order
  end
end