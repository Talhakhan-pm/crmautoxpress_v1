# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Only run seed data in development and test environments
unless Rails.env.production?
  puts "🌱 Starting AutoXpress CRM seed data..."

  # Clear existing data in development
  if Rails.env.development?
    puts "🧹 Cleaning existing data..."
    Activity.destroy_all
    Dispatch.destroy_all
    Order.destroy_all
    Product.destroy_all
    Supplier.destroy_all
    Customer.destroy_all
    AgentCallback.destroy_all
    User.destroy_all
  end

# Create Users (Agents)
puts "👥 Creating users/agents..."
users = User.create!([
  {
    email: "ayesha@autoxpress.com",
    password: "password123",
    password_confirmation: "password123"
  },
  {
    email: "murtaza@autoxpress.com", 
    password: "password123",
    password_confirmation: "password123"
  },
  {
    email: "sarah@autoxpress.com",
    password: "password123", 
    password_confirmation: "password123"
  },
  {
    email: "mike@autoxpress.com",
    password: "password123",
    password_confirmation: "password123"
  },
  {
    email: "jennifer@autoxpress.com",
    password: "password123",
    password_confirmation: "password123"
  }
])

puts "✅ Created #{users.count} users"

# Create Customers
puts "🙍 Creating customers..."
customers = Customer.create!([
  {
    name: "Joe Martinez",
    phone_number: "(817) 489-4064",
    email: "joe.martinez@email.com",
    full_address: "1234 Main St, Fort Worth, TX 76107",
    source_campaign: "google_ads",
    utm_source: "google",
    utm_campaign: "motor_mounts_tx",
    status: "active"
  },
  {
    name: "Murtaza Ali",
    phone_number: "(301) 943-2129", 
    email: "murtaza.ali@email.com",
    full_address: "567 Oak Ave, Silver Spring, MD 20910",
    source_campaign: "facebook_ads",
    utm_source: "facebook",
    utm_campaign: "door_locks_md",
    status: "active"
  },
  {
    name: "Jerry Steinbach",
    phone_number: "(320) 522-8169",
    email: "jerry.steinbach@email.com", 
    full_address: "890 Pine Rd, Glencoe, MN 55332",
    source_campaign: "google_ads",
    utm_source: "google",
    utm_campaign: "classic_parts_mn",
    status: "active"
  },
  {
    name: "Sarah Johnson",
    phone_number: "(512) 789-2345",
    email: "sarah.johnson@email.com",
    full_address: "456 Cedar St, Austin, TX 78701",
    source_campaign: "bing_ads",
    utm_source: "bing", 
    utm_campaign: "brake_parts_tx",
    status: "active"
  },
  {
    name: "Michael Chen",
    phone_number: "(213) 555-0123",
    email: "michael.chen@email.com",
    full_address: "789 Sunset Blvd, Los Angeles, CA 90210",
    source_campaign: "google_ads",
    utm_source: "google",
    utm_campaign: "engine_parts_ca", 
    status: "active"
  },
  {
    name: "Lisa Rodriguez",
    phone_number: "(305) 444-5678",
    email: "lisa.rodriguez@email.com",
    full_address: "321 Ocean Dr, Miami, FL 33139",
    source_campaign: "facebook_ads",
    utm_source: "facebook",
    utm_campaign: "suspension_fl",
    status: "active"
  },
  {
    name: "David Thompson",
    phone_number: "(602) 987-6543",
    email: "david.thompson@email.com",
    full_address: "654 Desert Rd, Phoenix, AZ 85001",
    source_campaign: "google_ads",
    utm_source: "google", 
    utm_campaign: "transmission_az",
    status: "active"
  },
  {
    name: "Amanda Wilson",
    phone_number: "(206) 321-9876",
    email: "amanda.wilson@email.com",
    full_address: "987 Rain St, Seattle, WA 98101",
    source_campaign: "bing_ads",
    utm_source: "bing",
    utm_campaign: "electrical_wa",
    status: "active"
  }
])

puts "✅ Created #{customers.count} customers"

# Create Products
puts "📦 Creating products..."
products = Product.create!([
  {
    name: "Engine Motor Mounts Set",
    part_number: "MM-FORD-2007-001",
    oem_part_number: "7L8Z-6038-A",
    description: "Complete set of engine motor mounts for Ford Fusion 2007-2012",
    category: "engine",
    vendor_name: "MountTech Solutions",
    vendor_cost: 45.99,
    selling_price: 89.99,
    lead_time_days: 3,
    vehicle_compatibility: "Ford Fusion 2007-2012, Mercury Milan 2007-2010",
    status: "active",
    source: "catalog"
  },
  {
    name: "Rear Door Lock Actuator", 
    part_number: "DLA-FORD-E150-RR",
    oem_part_number: "F7UZ-5426412-AB",
    description: "Rear right door lock actuator for Ford E-Series vans",
    category: "electrical",
    vendor_name: "LockPro Parts",
    vendor_cost: 32.50,
    selling_price: 67.99,
    lead_time_days: 2,
    vehicle_compatibility: "Ford E150/E250/E350 1997-2008",
    status: "active",
    source: "catalog"
  },
  {
    name: "Quarter Panel Rocker Panel Set",
    part_number: "QP-GALAXIE-1969-LH",
    oem_part_number: "C9ZZ-6527894-L",
    description: "Left hand quarter panel and rocker panel assembly for classic Galaxie",
    category: "body",
    vendor_name: "Classic Ford Restoration",
    vendor_cost: 245.00,
    selling_price: 449.99,
    lead_time_days: 7,
    vehicle_compatibility: "Ford Galaxie 500 1968-1970",
    status: "active",
    source: "catalog"
  },
  {
    name: "Brake Pad Set - Front",
    part_number: "BP-UNIV-2020-F",
    oem_part_number: "D1060-JA00A",
    description: "Ceramic brake pads for front wheels",
    category: "brakes",
    vendor_name: "StopTech Brakes",
    vendor_cost: 28.99,
    selling_price: 59.99,
    lead_time_days: 1,
    vehicle_compatibility: "Universal fitment for most 2015+ vehicles",
    status: "active",
    source: "catalog"
  },
  {
    name: "Engine Air Filter",
    part_number: "AF-2021-STD",
    oem_part_number: "16546-JA00B",
    description: "High-flow engine air filter",
    category: "engine",
    vendor_name: "FilterMax Pro",
    vendor_cost: 12.50,
    selling_price: 26.99,
    lead_time_days: 1,
    vehicle_compatibility: "Most 2018+ sedans and SUVs",
    status: "active",
    source: "catalog"
  },
  {
    name: "Shock Absorber Set",
    part_number: "SA-SUSP-2019-R",
    oem_part_number: "56110-4HA0A",
    description: "Rear shock absorber pair for SUVs",
    category: "suspension",
    vendor_name: "RideControl Systems",
    vendor_cost: 67.99,
    selling_price: 139.99,
    lead_time_days: 2,
    vehicle_compatibility: "Most mid-size SUVs 2016+",
    status: "active",
    source: "catalog"
  },
  {
    name: "Transmission Filter Kit",
    part_number: "TF-AUTO-2020-K",
    oem_part_number: "25420-3JX0A",
    description: "Complete transmission filter and gasket kit",
    category: "transmission",
    vendor_name: "TransParts Direct",
    vendor_cost: 23.75,
    selling_price: 48.99,
    lead_time_days: 2,
    vehicle_compatibility: "Automatic transmissions 2017+",
    status: "active",
    source: "catalog"
  },
  {
    name: "Alternator Assembly",
    part_number: "ALT-ELEC-2021-110A",
    oem_part_number: "23100-JA10B",
    description: "110A alternator with pulley",
    category: "electrical",
    vendor_name: "PowerGen Parts",
    vendor_cost: 89.50,
    selling_price: 179.99,
    lead_time_days: 3,
    vehicle_compatibility: "Most 4-cylinder engines 2019+",
    status: "active",
    source: "catalog"
  }
])

puts "✅ Created #{products.count} products"

# Create Suppliers
puts "🏭 Creating suppliers..."
suppliers = Supplier.create!([
  {
    name: "MountTech Solutions",
    supplier_notes: "Specializes in engine components and motor mounts. Contact: David Chen (555) 123-4567",
    source: "catalog"
  },
  {
    name: "AutoLock Distributors", 
    supplier_notes: "Door components and actuators specialist. Contact: Sarah Williams (555) 234-5678",
    source: "catalog"
  },
  {
    name: "BrakePro Industries",
    supplier_notes: "Premium brake components supplier. Contact: Michael Rodriguez (555) 345-6789",
    source: "catalog"
  },
  {
    name: "ElectroAuto Parts",
    supplier_notes: "Electrical components and sensors. Contact: Jennifer Kim (555) 456-7890",
    source: "catalog"
  },
  {
    name: "Suspension Masters",
    supplier_notes: "Suspension and steering components. Contact: Robert Johnson (555) 567-8901",
    source: "catalog"
  }
])

puts "✅ Created #{suppliers.count} suppliers"

# Create Agent Callbacks
puts "📞 Creating agent callbacks..."
callbacks = AgentCallback.create!([
  {
    customer_name: "Joe Martinez",
    phone_number: "(817) 489-4064",
    car_make_model: "Ford Fusion",
    year: 2007,
    product: "Engine Motor Mounts Set",
    zip_code: "76107",
    status: "sale",
    follow_up_date: 3.days.ago,
    agent: "Ayesha",
    notes: "Customer confirmed purchase, very satisfied",
    user: users[0]
  },
  {
    customer_name: "Murtaza Ali", 
    phone_number: "(301) 943-2129",
    car_make_model: "Ford E150",
    year: 2003,
    product: "Rear Door Lock Actuator",
    zip_code: "20910",
    status: "already_purchased",
    follow_up_date: 5.days.ago,
    agent: "Murtaza",
    notes: "Customer found part elsewhere",
    user: users[1]
  },
  {
    customer_name: "Jerry Steinbach",
    phone_number: "(320) 522-8169", 
    car_make_model: "Ford Galaxie 500",
    year: 1969,
    product: "Quarter Panel Rocker Panel Set",
    zip_code: "55332",
    status: "follow_up",
    follow_up_date: Date.current + 2.days,
    agent: "Sarah",
    notes: "Customer needs time to decide, call back next week",
    user: users[2]
  },
  {
    customer_name: "Sarah Johnson",
    phone_number: "(512) 789-2345",
    car_make_model: "Honda Accord",
    year: 2020,
    product: "Brake Pad Set - Front", 
    zip_code: "78701",
    status: "payment_link",
    follow_up_date: Date.current,
    agent: "Mike",
    notes: "Payment link sent, waiting for completion",
    user: users[3]
  },
  {
    customer_name: "Michael Chen",
    phone_number: "(213) 555-0123",
    car_make_model: "Toyota Camry",
    year: 2021,
    product: "Engine Air Filter",
    zip_code: "90210", 
    status: "pending",
    follow_up_date: Date.current + 1.day,
    agent: "Jennifer",
    notes: "Interested customer, needs quote",
    user: users[4]
  }
])

puts "✅ Created #{callbacks.count} agent callbacks"

# Create Orders with varying statuses and dates
puts "🛒 Creating orders..."
orders_data = [
  {
    customer: customers[0],
    product: products[0],
    agent: users[0],
    callback: callbacks[0],
    order_status: "delivered",
    priority: "standard",
    created_days_ago: 15,
    product_price: 89.99,
    tax_amount: 7.20,
    shipping_cost: 12.99,
    tracking_number: "1Z999AA1234567890",
    source_channel: "phone",
    commission_amount: 18.00,
    comments: "Customer very happy with the product quality",
    estimated_delivery: 10.days.ago
  },
  {
    customer: customers[1], 
    product: products[1],
    agent: users[1],
    callback: callbacks[1],
    order_status: "cancelled",
    priority: "low",
    created_days_ago: 12,
    product_price: 67.99,
    tax_amount: 5.44,
    shipping_cost: 9.99,
    source_channel: "phone",
    commission_amount: 13.60,
    comments: "Customer cancelled - found cheaper elsewhere",
    internal_notes: "Lost to competitor pricing"
  },
  {
    customer: customers[2],
    product: products[2], 
    agent: users[2],
    callback: callbacks[2],
    order_status: "pending",
    priority: "high",
    created_days_ago: 2,
    product_price: 449.99,
    tax_amount: 36.00,
    shipping_cost: 29.99,
    source_channel: "phone",
    commission_amount: 90.00,
    comments: "Classic car restoration project - premium customer",
    warranty_terms: "90-day warranty on all body panels"
  },
  {
    customer: customers[3],
    product: products[3],
    agent: users[3], 
    callback: callbacks[3],
    order_status: "confirmed",
    priority: "standard",
    created_days_ago: 1,
    product_price: 59.99,
    tax_amount: 4.80,
    shipping_cost: 8.99,
    source_channel: "web",
    commission_amount: 12.00,
    comments: "Repeat customer - always reliable"
  },
  {
    customer: customers[4],
    product: products[4],
    agent: users[4],
    callback: callbacks[4],
    order_status: "processing", 
    priority: "rush",
    created_days_ago: 1,
    product_price: 26.99,
    tax_amount: 2.16,
    shipping_cost: 5.99,
    source_channel: "phone",
    commission_amount: 5.40,
    comments: "Rush order - customer needs by Friday"
  },
  {
    customer: customers[5],
    product: products[5],
    agent: users[0],
    callback: nil,
    order_status: "shipped",
    priority: "standard",
    created_days_ago: 5,
    product_price: 139.99,
    tax_amount: 11.20,
    shipping_cost: 15.99,
    tracking_number: "1Z999AA1987654321",
    source_channel: "web",
    commission_amount: 28.00,
    comments: "Direct web order - no callback needed",
    estimated_delivery: Date.current + 2.days
  },
  {
    customer: customers[6],
    product: products[6],
    agent: users[1],
    callback: nil,
    order_status: "confirmed",
    priority: "standard", 
    created_days_ago: 3,
    product_price: 48.99,
    tax_amount: 3.92,
    shipping_cost: 7.99,
    source_channel: "email",
    commission_amount: 9.80,
    comments: "Customer contacted via email inquiry"
  },
  {
    customer: customers[7],
    product: products[7],
    agent: users[2],
    callback: nil,
    order_status: "processing",
    priority: "urgent",
    created_days_ago: 0,
    product_price: 179.99,
    tax_amount: 14.40,
    shipping_cost: 19.99,
    source_channel: "phone",
    commission_amount: 36.00,
    comments: "Urgent replacement needed - vehicle broken down",
    internal_notes: "Expedite shipping - customer stranded"
  }
]

orders = []
orders_data.each_with_index do |order_data, index|
  order = Order.create!(
    customer: order_data[:customer],
    product: order_data[:product], 
    agent: order_data[:agent],
    agent_callback: order_data[:callback],
    processing_agent: order_data[:agent],
    
    customer_name: order_data[:customer].name,
    customer_phone: order_data[:customer].phone_number,
    customer_email: order_data[:customer].email,
    customer_address: order_data[:customer].full_address,
    
    product_name: order_data[:product].name,
    car_year: order_data[:customer].name.include?("Jerry") ? 1969 : (2018..2023).to_a.sample,
    car_make_model: ["Honda Accord", "Toyota Camry", "Ford F-150", "Nissan Altima", "BMW 3 Series"].sample,
    
    order_status: order_data[:order_status],
    priority: order_data[:priority],
    order_date: order_data[:created_days_ago].days.ago,
    
    product_price: order_data[:product_price],
    tax_amount: order_data[:tax_amount],
    shipping_cost: order_data[:shipping_cost],
    total_amount: (order_data[:product_price] + order_data[:tax_amount] + order_data[:shipping_cost]),
    
    tracking_number: order_data[:tracking_number],
    estimated_delivery: order_data[:estimated_delivery],
    
    source_channel: order_data[:source_channel],
    commission_amount: order_data[:commission_amount],
    
    comments: order_data[:comments],
    internal_notes: order_data[:internal_notes],
    warranty_terms: order_data[:warranty_terms],
    
    last_modified_by: order_data[:agent].email
  )
  
  orders << order
  
  # Update created_at to simulate realistic timing
  order.update_column(:created_at, order_data[:created_days_ago].days.ago)
  order.update_column(:updated_at, (order_data[:created_days_ago] - rand(0..2)).days.ago)
end

puts "✅ Created #{orders.count} orders"

# Create some additional activities to show rich timeline
puts "📊 Creating activity timeline..."
activities_count = 0

orders.each do |order|
  # Create activity when order was created
  Activity.create!(
    trackable: order,
    user: order.agent,
    action: "created",
    ip_address: ["192.168.1.#{rand(1..255)}", "10.0.0.#{rand(1..255)}"].sample,
    user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
  ).update_column(:created_at, order.created_at)
  activities_count += 1
  
  # Add some view activities
  rand(1..3).times do
    Activity.create!(
      trackable: order,
      user: [order.agent, order.processing_agent, users.sample].compact.sample,
      action: "viewed",
      ip_address: "192.168.1.#{rand(1..255)}",
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    ).update_column(:created_at, rand(order.created_at..Time.current))
    activities_count += 1
  end
  
  # Add status change activities for non-pending orders
  unless order.pending?
    Activity.create!(
      trackable: order,
      user: order.agent,
      action: "updated",
      field_changed: "order_status",
      old_value: "pending",
      new_value: "confirmed",
      ip_address: "192.168.1.#{rand(1..255)}",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    ).update_column(:created_at, order.created_at + 1.hour)
    activities_count += 1
    
    if %w[processing shipped delivered].include?(order.order_status)
      Activity.create!(
        trackable: order,
        user: order.processing_agent || order.agent,
        action: "updated", 
        field_changed: "order_status",
        old_value: "confirmed",
        new_value: order.order_status,
        ip_address: "192.168.1.#{rand(1..255)}",
        user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      ).update_column(:created_at, order.created_at + rand(2..48).hours)
      activities_count += 1
    end
  end
end

puts "✅ Created #{activities_count} activities"

# Update existing dispatches for shipped/delivered orders
puts "🚚 Updating dispatches..."
dispatches_count = 0

orders.select { |o| %w[shipped delivered].include?(o.order_status) }.each do |order|
  if order.dispatch.present?
    dispatch = order.dispatch
    
    # Get a random supplier for this product (or use first if available)
    product_supplier = order.product.suppliers.first || suppliers.sample
    
    # Update order with supplier information
    order.update!(
      supplier_id: product_supplier&.id,
      supplier_order_number: "SUP-#{rand(100000..999999)}",
      supplier_cost: (order.product.vendor_cost * 0.9),
      supplier_shipment_proof: "https://supplier.com/proof/#{rand(1000..9999)}.pdf"
    )
    
    # Update dispatch with shipping and status information
    dispatch.update!(
      condition: ["new", "refurbished"].sample,
      payment_processor: ["stripe", "paypal", "square"].sample,
      payment_status: "paid",
      tracking_link: order.tracking_number ? "https://ups.com/track/#{order.tracking_number}" : nil,
      shipment_status: order.order_status == "delivered" ? "delivered" : "in_transit",
      dispatch_status: order.order_status == "delivered" ? "completed" : "shipped",
      comments: "Package shipped with tracking confirmation sent to customer",
      internal_notes: "Supplier delivered on time. Quality check passed."
    )
    
    # Update timestamps to match order
    dispatch.update_column(:created_at, order.created_at + 1.day)
    dispatch.update_column(:updated_at, order.updated_at)
    
    dispatches_count += 1
  end
end

puts "✅ Updated #{dispatches_count} dispatches"

  puts "\n🎉 AutoXpress CRM seed data complete!"
  puts "📊 Summary:"
  puts "   👥 Users: #{User.count}"
  puts "   🙍 Customers: #{Customer.count}" 
  puts "   📦 Products: #{Product.count}"
  puts "   📞 Callbacks: #{AgentCallback.count}"
  puts "   🛒 Orders: #{Order.count}"
  puts "   🚚 Dispatches: #{Dispatch.count}"
  puts "   📊 Activities: #{Activity.count}"
  puts "\n🚀 Ready to test your AutoXpress Order Management System!"
  puts "   📱 Login with any agent email (password: password123)"
  puts "   🌐 Visit http://localhost:3000/orders to see your orders"
else
  puts "🏭 Production environment detected - skipping seed data creation"
  puts "💡 Seed data only runs in development and test environments"
end