namespace :performance do
  desc "Reset communication counter caches for all agent callbacks"
  task reset_counter_caches: :environment do
    puts "Resetting communication counter caches..."
    
    AgentCallback.find_each do |callback|
      callback.update_column(:communications_count, callback.communications.count)
      print "."
    end
    
    puts "\nCounter cache reset complete!"
    puts "Total callbacks updated: #{AgentCallback.count}"
  end
end