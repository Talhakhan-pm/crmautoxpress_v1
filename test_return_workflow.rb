#!/usr/bin/env ruby

# Quick test script to verify return workflow
# Run with: ruby test_return_workflow.rb

require_relative 'config/environment'

puts "🧪 Testing Return Workflow Integration"
puts "=" * 50

# Test 1: Create a test order
puts "\n1. Creating test order..."
order = Order.create!(
  order_number: "TEST#{Time.current.to_i}",
  customer_name: "Test Customer",
  customer_phone: "555-1234",
  customer_email: "test@test.com",
  product_name: "Test Auto Part",
  product_price: 150.00,
  total_amount: 150.00,
  order_status: 'shipped',
  order_date: Time.current
)
puts "✅ Order created: #{order.order_number}"

# Test 2: Create a dispatch for the order
puts "\n2. Creating dispatch..."
dispatch = Dispatch.create!(
  order: order,
  dispatch_status: 'shipped',
  payment_status: 'paid'
)
puts "✅ Dispatch created with status: #{dispatch.dispatch_status}"

# Test 3: Test wrong_product refund creation (should go to pending_resolution)
puts "\n3. Testing wrong_product refund creation..."
refund = Refund.new(
  order: order,
  customer_name: order.customer_name,
  refund_amount: order.total_amount,
  original_charge_amount: order.total_amount,
  refund_reason: 'wrong_product'
)

if refund.save
  puts "✅ Refund created: #{refund.refund_number}"
  puts "   - Refund Stage: #{refund.refund_stage}"
  puts "   - Resolution Stage: #{refund.resolution_stage}"
  puts "   - Return Status: #{refund.return_status}"
  puts "   - Order Status After: #{order.reload.order_status}"
else
  puts "❌ Refund failed: #{refund.errors.full_messages.join(', ')}"
end

# Test 4: Test customer_changed_mind refund (should go to pending_refund)
puts "\n4. Creating second order for changed_mind test..."
order2 = Order.create!(
  order_number: "TEST#{Time.current.to_i + 1}",
  customer_name: "Test Customer 2",
  customer_phone: "555-5678",
  customer_email: "test2@test.com",
  product_name: "Test Auto Part 2",
  product_price: 200.00,
  total_amount: 200.00,
  order_status: 'shipped',
  order_date: Time.current
)

dispatch2 = Dispatch.create!(
  order: order2,
  dispatch_status: 'shipped',
  payment_status: 'paid'
)

refund2 = Refund.new(
  order: order2,
  customer_name: order2.customer_name,
  refund_amount: order2.total_amount,
  original_charge_amount: order2.total_amount,
  refund_reason: 'customer_changed_mind'
)

if refund2.save
  puts "✅ Second refund created: #{refund2.refund_number}"
  puts "   - Refund Stage: #{refund2.refund_stage}"
  puts "   - Return Status: #{refund2.return_status}"
else
  puts "❌ Second refund failed: #{refund2.errors.full_messages.join(', ')}"
end

# Test 5: Verify resolution center can find the return request
puts "\n5. Testing resolution center integration..."
pending_resolutions = Refund.where(refund_stage: 'pending_resolution')
puts "✅ Found #{pending_resolutions.count} refund(s) in pending_resolution"

pending_resolutions.each do |ref|
  puts "   - #{ref.refund_number}: #{ref.refund_reason} (#{ref.resolution_stage})"
end

puts "\n🎉 Return workflow test completed!"
puts "\nNext steps:"
puts "1. Run: rails db:migrate (if not already run)"
puts "2. Start server: rails server"
puts "3. Test UI dropdown functionality"
puts "4. Verify resolution center shows return requests"

# Cleanup (optional)
puts "\n🧹 Cleaning up test data..."
[refund, refund2, dispatch, dispatch2, order, order2].each(&:destroy)
puts "✅ Test data cleaned up"