namespace :performance do
  desc "Generate large dataset for performance testing (production-safe)"
  task :seed_large_dataset => :environment do
    puts "🚀 Starting performance testing data generation..."
    puts "Environment: #{Rails.env}"
    
    # Safety check - require explicit confirmation for production
    if Rails.env.production?
      puts "⚠️  WARNING: This will add test data to PRODUCTION!"
      puts "⚠️  This could affect real customer data and performance."
      puts "⚠️  Type 'I understand and want to proceed' to continue:"
      
      confirmation = STDIN.gets.chomp
      unless confirmation == "I understand and want to proceed"
        puts "❌ Aborted. Production data unchanged."
        exit
      end
    end
    
    # Configuration
    target_orders = ENV['ORDERS'] || 150
    target_callbacks = ENV['CALLBACKS'] || 200
    target_customers = ENV['CUSTOMERS'] || 100
    
    puts "📊 Target dataset size:"
    puts "   Orders: #{target_orders}"
    puts "   Callbacks: #{target_callbacks}"
    puts "   Customers: #{target_customers}"
    
    # Ensure we have base data
    ensure_base_data
    
    # Generate additional customers
    puts "👥 Generating additional customers..."
    generate_customers(target_customers.to_i)
    
    # Generate additional callbacks
    puts "📞 Generating additional callbacks..."
    generate_callbacks(target_callbacks.to_i)
    
    # Generate additional orders
    puts "🛒 Generating additional orders..."
    generate_orders(target_orders.to_i)
    
    # Generate realistic activity data
    puts "📊 Generating activity timeline..."
    generate_activities
    
    # Create dispatches for shipped orders
    puts "🚚 Creating dispatches..."
    generate_dispatches
    
    # Add some refunds for testing
    puts "💰 Creating sample refunds..."
    generate_refunds
    
    puts "\n✅ Performance testing dataset complete!"
    print_final_stats
  end
  
  desc "Clean up performance testing data (keeps production data safe)"
  task :cleanup => :environment do
    puts "🧹 Cleaning up performance testing data..."
    
    if Rails.env.production?
      puts "⚠️  WARNING: This will remove test data from PRODUCTION!"
      puts "⚠️  Only data marked as 'performance_test' will be removed."
      puts "⚠️  Type 'cleanup confirmed' to continue:"
      
      confirmation = STDIN.gets.chomp
      unless confirmation == "cleanup confirmed"
        puts "❌ Cleanup cancelled."
        exit
      end
    end
    
    # Remove test data (marked with specific patterns)
    test_customers = Customer.where("name LIKE 'Test Customer %' OR email LIKE '%@perftest.com'")
    test_orders = Order.joins(:customer).where(customers: { id: test_customers.ids })
    
    puts "Removing #{test_orders.count} test orders..."
    test_orders.destroy_all
    
    puts "Removing #{test_customers.count} test customers..."
    test_customers.destroy_all
    
    # Remove test callbacks
    test_callbacks = AgentCallback.where("customer_name LIKE 'Test Customer %'")
    puts "Removing #{test_callbacks.count} test callbacks..."
    test_callbacks.destroy_all
    
    puts "✅ Cleanup complete!"
  end
  
  private
  
  def ensure_base_data
    # Ensure we have at least basic users and products
    if User.count == 0
      puts "Creating base users..."
      User.create!([
        { email: "admin@autoxpress.com", password: "password123", password_confirmation: "password123" },
        { email: "agent1@autoxpress.com", password: "password123", password_confirmation: "password123" },
        { email: "agent2@autoxpress.com", password: "password123", password_confirmation: "password123" },
        { email: "agent3@autoxpress.com", password: "password123", password_confirmation: "password123" }
      ])
    end
    
    if Product.count < 10
      puts "Creating base products..."
      generate_base_products
    end
    
    if Supplier.count < 5
      puts "Creating base suppliers..."
      generate_base_suppliers
    end
  end
  
  def generate_customers(target_count)
    current_count = Customer.count
    needed = target_count - current_count
    
    if needed <= 0
      puts "Already have #{current_count} customers (target: #{target_count})"
      return
    end
    
    puts "Creating #{needed} additional customers..."
    
    first_names = %w[John Jane Mike Sarah David Lisa Robert Jennifer William Patricia Michael Linda James Barbara Christopher Maria Mark Susan Joseph Karen Thomas Nancy Daniel Betty Paul Helen Donald Carol George Ruth Kenneth Lisa Edward Sandra Ronald Nancy Joshua Donna Walter Cynthia Harold Angela Arthur Shirley Gary Frances Harold Alice Stephen Martha Eric Diane Jerry Angela Wayne Julie Arthur Anne Russell Virginia Willie Cheryl Ralph Evelyn Edward Jean Harold Frances Roy Diana Eugene Marie Eugene Rose Louis Ruth Bruce Catherine Billy Teresa Albert Frances Roger Ann Henry Tammy Eugene Beverly Wayne Janice Gerald Denise Harold Gloria Eugene Kathryn Harold Judith Carl Rebecca Terry Annie Harold Janet Matthew Maria]
    
    last_names = %w[Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson Walker Young Allen King Wright Scott Torres Nguyen Hill Flores Green Adams Nelson Baker Hall Rivera Campbell Mitchell Carter Roberts Gomez Phillips Evans Turner Diaz Parker Cruz Edwards Collins Reyes Stewart Morris Morales Murphy Cook Rogers Gutierrez Ortiz Morgan Cooper Ramos Peterson Bailey Reed Kelly Howard Ramos Kim Cox Ward Richardson Watson Brooks Chavez Wood James Bennett Gray Mendoza Ruiz Hughes Price Alvarez Castillo Sanders Patel Myers Long Ross Foster Jimenez]
    
    cities_states = [
      ["Austin", "TX", "787"], ["Houston", "TX", "770"], ["Dallas", "TX", "752"], ["San Antonio", "TX", "782"],
      ["Los Angeles", "CA", "900"], ["San Francisco", "CA", "941"], ["San Diego", "CA", "921"], ["Sacramento", "CA", "958"],
      ["Miami", "FL", "331"], ["Orlando", "FL", "328"], ["Tampa", "FL", "336"], ["Jacksonville", "FL", "322"],
      ["New York", "NY", "100"], ["Buffalo", "NY", "142"], ["Rochester", "NY", "146"], ["Syracuse", "NY", "132"],
      ["Chicago", "IL", "606"], ["Springfield", "IL", "627"], ["Rockford", "IL", "611"], ["Peoria", "IL", "616"],
      ["Phoenix", "AZ", "850"], ["Tucson", "AZ", "857"], ["Mesa", "AZ", "852"], ["Chandler", "AZ", "852"],
      ["Seattle", "WA", "981"], ["Spokane", "WA", "992"], ["Tacoma", "WA", "984"], ["Vancouver", "WA", "986"],
      ["Denver", "CO", "802"], ["Colorado Springs", "CO", "809"], ["Aurora", "CO", "800"], ["Fort Collins", "CO", "805"],
      ["Atlanta", "GA", "303"], ["Savannah", "GA", "314"], ["Columbus", "GA", "319"], ["Augusta", "GA", "309"],
      ["Las Vegas", "NV", "891"], ["Reno", "NV", "895"], ["Henderson", "NV", "890"], ["Carson City", "NV", "897"]
    ]
    
    sources = ["google_ads", "facebook_ads", "bing_ads", "organic_search", "referral", "direct"]
    campaigns = ["brake_parts", "engine_components", "electrical_parts", "suspension", "transmission", "exhaust_systems", "filters", "belts_hoses"]
    
    customers_to_create = []
    
    needed.times do |i|
      city_data = cities_states.sample
      city, state, zip_prefix = city_data
      
      source = sources.sample
      campaign = campaigns.sample
      
      customers_to_create << {
        name: "Test Customer #{current_count + i + 1} #{first_names.sample} #{last_names.sample}",
        phone_number: "(#{rand(200..999)}) #{rand(200..999)}-#{rand(1000..9999)}",
        email: "testcustomer#{current_count + i + 1}@perftest.com",
        full_address: "#{rand(100..9999)} #{['Main St', 'Oak Ave', 'Pine Rd', 'Elm St', 'Cedar Ln', 'Maple Dr'].sample}, #{city}, #{state} #{zip_prefix}#{rand(10..99)}",
        source_campaign: source,
        utm_source: source.split('_').first,
        utm_campaign: "#{campaign}_#{state.downcase}",
        status: ["active", "inactive"].sample,
        created_at: rand(6.months.ago..Time.current),
        updated_at: rand(1.month.ago..Time.current)
      }
    end
    
    customers_to_create.each do |customer_data|
      Customer.create!(customer_data)
    end
    puts "✅ Created #{needed} customers"
  end
  
  def generate_callbacks(target_count)
    current_count = AgentCallback.count
    needed = target_count - current_count
    
    if needed <= 0
      puts "Already have #{current_count} callbacks (target: #{target_count})"
      return
    end
    
    puts "Creating #{needed} additional callbacks..."
    
    customers = Customer.limit(100).order('RANDOM()').to_a
    users = User.all.to_a
    products = Product.all.to_a
    
    car_makes = ["Honda Accord", "Toyota Camry", "Ford F-150", "Nissan Altima", "BMW 3 Series", "Mercedes C-Class", "Audi A4", "Lexus ES", "Acura TLX", "Infiniti Q50", "Mazda 6", "Subaru Legacy", "Volkswagen Passat", "Hyundai Sonata", "Kia Optima", "Chevrolet Malibu", "Dodge Charger", "Chrysler 300", "Buick LaCrosse", "Lincoln MKZ"]
    
    statuses = ["pending", "not_interested", "already_purchased", "sale", "payment_link", "follow_up"]
    
    callbacks_to_create = []
    
    needed.times do |i|
      customer = customers.sample
      user = users.sample
      product = products.sample
      status = statuses.sample
      
      follow_up_date = case status
      when "follow_up"
        rand(1.day.from_now..1.week.from_now)
      when "payment_link"
        rand(Time.current..2.days.from_now)
      when "pending", "contacted"
        rand(Time.current..3.days.from_now)
      else
        nil
      end
      
      callbacks_to_create << {
        customer_name: customer.name,
        phone_number: customer.phone_number,
        car_make_model: car_makes.sample,
        year: rand(2010..2024),
        product: product.name,
        zip_code: customer.full_address.split.last,
        status: status,
        follow_up_date: follow_up_date,
        agent: user.email.split('@').first.humanize,
        notes: generate_callback_notes(status),
        user_id: user.id,
        created_at: rand(3.months.ago..Time.current),
        updated_at: rand(1.week.ago..Time.current)
      }
    end
    
    callbacks_to_create.each do |callback_data|
      AgentCallback.create!(callback_data)
    end
    puts "✅ Created #{needed} callbacks"
  end
  
  def generate_orders(target_count)
    current_count = Order.count
    needed = target_count - current_count
    
    if needed <= 0
      puts "Already have #{current_count} orders (target: #{target_count})"
      return
    end
    
    puts "Creating #{needed} additional orders..."
    
    customers = Customer.where("name LIKE 'Test Customer %'").to_a
    if customers.empty?
      customers = Customer.limit(50).to_a
    end
    
    products = Product.all.to_a
    users = User.all.to_a
    statuses = ["pending", "confirmed", "processing", "shipped", "delivered", "cancelled"]
    priorities = ["low", "standard", "high", "rush", "urgent"]
    channels = ["phone", "web", "email", "walk_in"]
    
    orders_to_create = []
    
    needed.times do |i|
      customer = customers.sample
      product = products.sample
      agent = users.sample
      status = statuses.sample
      priority = priorities.sample
      channel = channels.sample
      
      product_price = product.selling_price || rand(25.99..499.99)
      tax_rate = rand(0.05..0.10)
      tax_amount = (product_price * tax_rate).round(2)
      shipping_cost = case priority
      when "rush", "urgent"
        rand(15.99..29.99)
      else
        rand(5.99..15.99)
      end
      
      created_date = rand(6.months.ago..Time.current)
      
      tracking_number = %w[shipped delivered].include?(status) ? "1Z999AA#{rand(1000000000..9999999999)}" : nil
      estimated_delivery = %w[shipped processing confirmed].include?(status) ? rand(2.days.from_now..2.weeks.from_now) : nil
      
      orders_to_create << {
        customer_id: customer.id,
        product_id: product.id,
        agent_id: agent.id,
        processing_agent_id: agent.id,
        
        customer_name: customer.name,
        customer_phone: customer.phone_number,
        customer_email: customer.email,
        customer_address: customer.full_address,
        
        product_name: product.name,
        car_year: rand(2010..2024),
        car_make_model: ["Honda Accord", "Toyota Camry", "Ford F-150", "Nissan Altima", "BMW 3 Series"].sample,
        
        order_status: status,
        priority: priority,
        order_date: created_date,
        
        product_price: product_price,
        tax_amount: tax_amount,
        shipping_cost: shipping_cost,
        total_amount: product_price + tax_amount + shipping_cost,
        
        tracking_number: tracking_number,
        estimated_delivery: estimated_delivery,
        
        source_channel: channel,
        commission_amount: (product_price * rand(0.10..0.20)).round(2),
        
        comments: generate_order_comments(status, priority),
        internal_notes: generate_internal_notes(status),
        warranty_terms: product.category == "engine" ? "90-day warranty included" : nil,
        warranty_period_days: rand(30..365),
        return_window_days: rand(14..30),
        
        last_modified_by: agent.email,
        created_at: created_date,
        updated_at: rand(created_date..Time.current)
      }
    end
    
    orders_to_create.each do |order_data|
      Order.create!(order_data)
    end
    puts "✅ Created #{needed} orders"
  end
  
  def generate_activities
    # Generate activities for recent orders only (performance)
    recent_orders = Order.where('created_at > ?', 1.month.ago).includes(:agent).limit(100)
    activities_count = 0
    
    recent_orders.each do |order|
      # Create order activity
      Activity.create!(
        trackable: order,
        user: order.agent,
        action: "created",
        ip_address: "192.168.1.#{rand(1..255)}",
        user_agent: "Mozilla/5.0 (Test Agent)",
        created_at: order.created_at
      )
      activities_count += 1
      
      # Add 1-3 view activities
      rand(1..3).times do
        Activity.create!(
          trackable: order,
          user: User.all.sample,
          action: "viewed",
          ip_address: "192.168.1.#{rand(1..255)}",
          user_agent: "Mozilla/5.0 (Test Agent)",
          created_at: rand(order.created_at..Time.current)
        )
        activities_count += 1
      end
      
      # Add status change if not pending
      unless order.order_status == "pending"
        Activity.create!(
          trackable: order,
          user: order.agent,
          action: "updated",
          field_changed: "order_status",
          old_value: "pending",
          new_value: order.order_status,
          ip_address: "192.168.1.#{rand(1..255)}",
          user_agent: "Mozilla/5.0 (Test Agent)",
          created_at: order.created_at + rand(1..48).hours
        )
        activities_count += 1
      end
    end
    
    puts "✅ Created #{activities_count} activities"
  end
  
  def generate_dispatches
    shipped_orders = Order.where(order_status: ["shipped", "delivered"]).where('created_at > ?', 1.month.ago)
    dispatches_count = 0
    
    shipped_orders.each do |order|
      next if order.dispatch.present?
      
      dispatch = Dispatch.create!(
        order: order,
        processing_agent: order.agent,
        order_number: order.order_number,
        customer_name: order.customer_name,
        total_cost: order.total_amount,
        condition: ["new", "refurbished"].sample,
        payment_processor: ["stripe", "paypal", "square"].sample,
        payment_status: "paid",
        tracking_link: order.tracking_number ? "https://ups.com/track/#{order.tracking_number}" : nil,
        shipment_status: order.order_status == "delivered" ? "delivered" : "in_transit",
        dispatch_status: order.order_status == "delivered" ? "completed" : "shipped",
        comments: "Shipped with tracking - performance test data",
        internal_notes: "Generated for performance testing",
        created_at: order.created_at + 1.day,
        updated_at: order.updated_at
      )
      dispatches_count += 1
    end
    
    puts "✅ Created #{dispatches_count} dispatches"
  end
  
  def generate_refunds
    # Create a few refunds for testing
    delivered_orders = Order.where(order_status: "delivered").limit(5)
    refunds_count = 0
    
    delivered_orders.each do |order|
      next if order.refund.present?
      
      Refund.create!(
        order: order,
        refund_reason: ["wrong_product", "defective_product", "customer_changed_mind", "quality_issues"].sample,
        refund_amount: order.total_amount,
        customer_name: order.customer_name,
        original_charge_amount: order.total_amount,
        processing_agent: order.agent,
        resolution_stage: ["pending_customer_clarification", "pending_dispatch_decision", "resolution_completed"].sample,
        agent_notes: "Performance test refund - customer issue reported",
        created_at: rand(order.created_at..Time.current)
      )
      refunds_count += 1
    end
    
    puts "✅ Created #{refunds_count} refunds"
  end
  
  def generate_base_products
    base_products = [
      { name: "Brake Pad Set", category: "brakes", selling_price: 59.99, vendor_cost: 29.99 },
      { name: "Engine Air Filter", category: "engine", selling_price: 26.99, vendor_cost: 12.50 },
      { name: "Shock Absorber", category: "suspension", selling_price: 139.99, vendor_cost: 67.99 },
      { name: "Alternator", category: "electrical", selling_price: 179.99, vendor_cost: 89.50 },
      { name: "Transmission Filter", category: "transmission", selling_price: 48.99, vendor_cost: 23.75 },
      { name: "Starter Motor", category: "electrical", selling_price: 129.99, vendor_cost: 64.99 },
      { name: "Fuel Pump", category: "engine", selling_price: 199.99, vendor_cost: 99.99 },
      { name: "Radiator", category: "cooling", selling_price: 249.99, vendor_cost: 124.99 },
      { name: "Exhaust Muffler", category: "exhaust", selling_price: 89.99, vendor_cost: 44.99 },
      { name: "Clutch Kit", category: "transmission", selling_price: 299.99, vendor_cost: 149.99 }
    ]
    
    base_products.each do |product_data|
      Product.create!(
        name: product_data[:name],
        part_number: "PT-#{rand(1000..9999)}-#{product_data[:category].upcase}",
        description: "Performance test #{product_data[:name].downcase}",
        category: product_data[:category],
        vendor_name: "Test Vendor #{rand(1..5)}",
        vendor_cost: product_data[:vendor_cost],
        selling_price: product_data[:selling_price],
        lead_time_days: rand(1..7),
        vehicle_compatibility: "Universal fitment",
        status: "active",
        source: "catalog"
      )
    end
  end
  
  def generate_base_suppliers
    suppliers_data = [
      "Performance Parts Direct",
      "AutoZone Wholesale",
      "Brake Masters Supply",
      "Engine Components LLC",
      "Electrical Systems Pro"
    ]
    
    suppliers_data.each do |name|
      Supplier.create!(
        name: name,
        supplier_notes: "Performance testing supplier - #{name}",
        source: "catalog"
      )
    end
  end
  
  def generate_callback_notes(status)
    case status
    when "pending"
      "New lead - needs initial contact"
    when "follow_up"
      "Customer requested callback later"
    when "payment_link"
      "Payment link sent, awaiting completion"
    when "sale"
      "Successfully converted to sale!"
    when "already_purchased"
      "Customer found part elsewhere"
    when "not_interested"
      "Customer not interested at this time"
    else
      "Standard callback entry"
    end
  end
  
  def generate_order_comments(status, priority)
    case status
    when "pending"
      "Order received, awaiting confirmation"
    when "confirmed"
      priority == "rush" ? "Rush order - expedite processing" : "Order confirmed by customer"
    when "processing"
      "Order being prepared for shipment"
    when "shipped"
      "Package shipped with tracking provided"
    when "delivered"
      "Successfully delivered to customer"
    when "cancelled"
      "Order cancelled per customer request"
    else
      "Standard order processing"
    end
  end
  
  def generate_internal_notes(status)
    case status
    when "cancelled"
      "Customer cancelled - check for restocking fee"
    when "delivered"
      "Delivery confirmed - customer satisfied"
    when "shipped"
      "Tracking updated - estimated delivery on schedule"
    else
      nil
    end
  end
  
  def print_final_stats
    puts "📊 Final Dataset Statistics:"
    puts "   👥 Users: #{User.count}"
    puts "   🙍 Customers: #{Customer.count}"
    puts "   📦 Products: #{Product.count}"
    puts "   🏭 Suppliers: #{Supplier.count}"
    puts "   📞 Callbacks: #{AgentCallback.count}"
    puts "   🛒 Orders: #{Order.count}"
    puts "   🚚 Dispatches: #{Dispatch.count}"
    puts "   💰 Refunds: #{Refund.count if defined?(Refund)}"
    puts "   📊 Activities: #{Activity.count}"
    puts "\n🎯 Performance testing ready!"
    puts "   📈 Test pagination, filtering, and search with #{Order.count} orders"
    puts "   ⚡ Monitor response times and database performance"
    puts "   🔍 Check memory usage with large datasets"
  end
end