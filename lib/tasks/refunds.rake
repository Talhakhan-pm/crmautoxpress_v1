namespace :refunds do
  desc "Auto-escalate overdue refunds based on time rules"
  task escalate: :environment do
    puts "Starting refund auto-escalation process..."
    
    escalated_count = 0
    
    Refund.needs_escalation.find_each do |refund|
      if refund.auto_escalate_if_needed!
        escalated_count += 1
        puts "Escalated refund #{refund.refund_number} - #{refund.days_since_request} days old"
      end
    end
    
    puts "Auto-escalation complete: #{escalated_count} refunds escalated"
  end
  
  desc "Show refunds that need escalation"
  task check_escalation: :environment do
    puts "Checking refunds that need escalation..."
    
    Refund.needs_escalation.includes(:order).each do |refund|
      puts "#{refund.refund_number} - #{refund.refund_stage} - #{refund.days_since_request} days old - Order #{refund.order.order_number}"
    end
  end
end