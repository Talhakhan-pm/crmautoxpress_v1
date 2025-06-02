#!/usr/bin/env ruby

# Quick test script to verify return workflow
# Run with: ruby test_return_workflow.rb

require_relative 'config/environment'

puts "🔍 Checking Order AX20250602010 Status"
puts "=" * 50

# Search for the specific order
order = Order.find_by(order_number: "AX20250602010")

if order
  puts "\n📦 Order Found: #{order.order_number}"
  puts "   - Customer: #{order.customer_name}"
  puts "   - Product: #{order.product_name}"
  puts "   - Order Status: #{order.order_status}"
  puts "   - Source Channel: #{order.source_channel}"
  puts "   - Priority: #{order.priority}"
  puts "   - Created: #{order.created_at}"
  
  if order.dispatch.present?
    puts "\n🚚 Dispatch Information:"
    puts "   - Dispatch Status: #{order.dispatch.dispatch_status}"
    puts "   - Payment Status: #{order.dispatch.payment_status}"
    puts "   - Shipment Status: #{order.dispatch.shipment_status}"
    puts "   - Tracking Number: #{order.dispatch.tracking_number || 'None'}"
  else
    puts "\n🚚 No dispatch found for this order"
  end
  
  if order.refund.present?
    puts "\n💰 Refund Information:"
    puts "   - Refund Number: #{order.refund.refund_number}"
    puts "   - Refund Stage: #{order.refund.refund_stage}"
    puts "   - Return Status: #{order.refund.return_status}"
    puts "   - Resolution Stage: #{order.refund.resolution_stage}"
    puts "   - Amount: $#{order.refund.refund_amount}"
  else
    puts "\n💰 No refund found for this order"
  end
  
  if order.replacement_order_id.present?
    replacement = Order.find_by(id: order.replacement_order_id)
    if replacement
      puts "\n🔄 Replacement Order Information:"
      puts "   - Replacement Number: #{replacement.order_number}"
      puts "   - Status: #{replacement.order_status}"
      puts "   - Created: #{replacement.created_at}"
      if replacement.dispatch.present?
        puts "   - Dispatch Status: #{replacement.dispatch.dispatch_status}"
      end
    end
  else
    puts "\n🔄 No replacement order linked"
  end
  
else
  puts "\n❌ Order AX20250602010 not found in database"
end

# Fix existing replacement dispatches that are stuck in pending
puts "\n🔧 Fixing existing replacement dispatches..."
replacement_orders = Order.where(source_channel: 'replacement')
fixed_count = 0

replacement_orders.each do |repl_order|
  if repl_order.dispatch.present? && repl_order.dispatch.dispatch_status == 'pending'
    repl_order.dispatch.update!(
      dispatch_status: 'processing',
      payment_status: 'paid'
    )
    puts "✅ Fixed dispatch for replacement order: #{repl_order.order_number}"
    fixed_count += 1
  end
end

puts "✅ Fixed #{fixed_count} replacement dispatch(es)"

puts "\n🎉 Order status check and fix completed!"