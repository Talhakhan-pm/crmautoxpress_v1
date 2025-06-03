#!/usr/bin/env ruby

# Test script for status synchronization fixes
puts "=== Testing Status Synchronization Fixes ==="

# Test AX20250602001 (processing/cancelled issue)
order1 = Order.find_by(order_number: 'AX20250602001')
if order1
  puts "\n=== TESTING AX20250602001 ==="
  puts "Before: Order=#{order1.order_status}, Dispatch=#{order1.dispatch.dispatch_status}"
  
  if order1.refund&.pending_resolution?
    puts "Attempting auto-resolution..."
    resolved = order1.refund.auto_complete_resolution_if_resolved!
    puts "Auto-resolution result: #{resolved}"
  end
  
  puts "Triggering dispatch sync..."
  order1.dispatch.send(:sync_with_order)
  
  order1.reload
  puts "After: Order=#{order1.order_status}, Dispatch=#{order1.dispatch.dispatch_status}"
  puts "Refund stage: #{order1.refund&.refund_stage}"
  puts "Resolution stage: #{order1.refund&.resolution_stage}"
else
  puts "Order AX20250602001 not found"
end

# Test AX20250603001 (confirmed/completed issue)
order2 = Order.find_by(order_number: 'AX20250603001')
if order2
  puts "\n=== TESTING AX20250603001 ==="
  puts "Before: Order=#{order2.order_status}, Dispatch=#{order2.dispatch.dispatch_status}"
  
  if order2.refund&.pending_resolution?
    puts "Attempting auto-resolution..."
    resolved = order2.refund.auto_complete_resolution_if_resolved!
    puts "Auto-resolution result: #{resolved}"
  end
  
  puts "Triggering dispatch sync..."
  order2.dispatch.send(:sync_with_order)
  
  order2.reload
  puts "After: Order=#{order2.order_status}, Dispatch=#{order2.dispatch.dispatch_status}"
  puts "Refund stage: #{order2.refund&.refund_stage}"
  puts "Resolution stage: #{order2.refund&.resolution_stage}"
else
  puts "Order AX20250603001 not found"
end

# Test general auto-resolution scenarios
puts "\n=== TESTING AUTO-RESOLUTION SCENARIOS ==="

# Find refunds with pending resolutions
pending_refunds = Refund.where(refund_stage: 'pending_resolution')
puts "Found #{pending_refunds.count} refunds with pending resolution"

pending_refunds.each do |refund|
  puts "\nTesting refund #{refund.refund_number} (Order: #{refund.order.order_number})"
  puts "  Before: #{refund.refund_stage} / #{refund.resolution_stage}"
  
  resolved = refund.auto_complete_resolution_if_resolved!
  
  refund.reload
  puts "  After: #{refund.refund_stage} / #{refund.resolution_stage}"
  puts "  Auto-resolved: #{resolved}"
end

puts "\n=== Test Complete ==="