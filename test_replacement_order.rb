# Test script to investigate replacement order issue
# Run with: rails runner test_replacement_order.rb

puts "=== REPLACEMENT ORDER INVESTIGATION ==="
puts "Original Order: AX20250602001"
puts "Replacement Order: AX20250602009"
puts

# Find the original order
original_order = Order.find_by(order_number: "AX20250602001")
if original_order.nil?
  puts "❌ Original order AX20250602001 not found!"
  exit
end

# Find the replacement order
replacement_order = Order.find_by(order_number: "AX20250602009")
if replacement_order.nil?
  puts "❌ Replacement order AX20250602009 not found!"
  exit
end

puts "📦 Original Order Details:"
puts "  Order Number: #{original_order.order_number}"
puts "  Order Status: #{original_order.order_status}"
puts "  Customer: #{original_order.customer_name}"
puts "  Total: $#{original_order.total_amount}"
puts "  Display Status: #{original_order.display_status}"
puts "  Status Color: #{original_order.status_color}"
puts

puts "📦 Replacement Order Details:"
puts "  Order Number: #{replacement_order.order_number}"
puts "  Order Status: #{replacement_order.order_status}"
puts "  Customer: #{replacement_order.customer_name}"
puts "  Total: $#{replacement_order.total_amount}"
puts "  Original Order ID: #{replacement_order.original_order_id}"
puts "  Replacement Reason: #{replacement_order.replacement_reason}"
puts

puts "🔗 Relationship Analysis:"
puts "  Original has replacement_order_id: #{original_order.replacement_order_id}"
puts "  Replacement has original_order_id: #{replacement_order.original_order_id}"
puts "  original_order.has_replacement_order?: #{original_order.has_replacement_order?}"
puts "  replacement_order.is_replacement_order?: #{replacement_order.is_replacement_order?}"
puts

# Check if the replacement relationship is properly linked
if original_order.replacement_order_id != replacement_order.id
  puts "❌ ISSUE: Original order's replacement_order_id (#{original_order.replacement_order_id}) doesn't match replacement order ID (#{replacement_order.id})"
end

if replacement_order.original_order_id != original_order.id
  puts "❌ ISSUE: Replacement order's original_order_id (#{replacement_order.original_order_id}) doesn't match original order ID (#{original_order.id})"
end

puts "🔍 Original Order Status Analysis:"
puts "  Order.order_status: #{original_order.order_status}"
puts "  Order.has_pending_refund_resolution?: #{original_order.has_pending_refund_resolution?}"

# Check if there's a refund
if original_order.refund.present?
  puts "💰 Original Order Refund:"
  puts "  Refund Stage: #{original_order.refund.refund_stage}"
  puts "  Resolution Stage: #{original_order.refund.resolution_stage}"
  puts "  Replacement Order Number: #{original_order.refund.replacement_order_number}"
end

puts "🎯 Expected Behavior:"
puts "  When a replacement order is created, the original order should:"
puts "  1. Have its status updated to reflect the replacement"
puts "  2. Show in the UI that it has been replaced"
puts "  3. Not show as 'processing' anymore"
puts

puts "🔧 Potential Issues:"
if original_order.order_status == 'processing'
  puts "  ❌ Original order still shows as 'processing'"
  puts "  ✅ Should show as 'returned' or 'replaced' status"
end

if original_order.replacement_order_id.blank?
  puts "  ❌ Original order's replacement_order_id is not set"
  puts "  ✅ Should be set to #{replacement_order.id}"
end

if replacement_order.original_order_id.blank?
  puts "  ❌ Replacement order's original_order_id is not set" 
  puts "  ✅ Should be set to #{original_order.id}"
end

puts
puts "=== RECOMMENDATIONS ==="
puts "1. Check the replacement order creation logic"
puts "2. Ensure original order status is updated when replacement is created"
puts "3. Verify replacement relationship fields are properly set"
puts "4. Update display logic to show replacement status"