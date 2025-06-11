class AddCallbackDashboardPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Fix N+1 query for current caller lookup
    add_index :users, [:current_target_type, :current_target_id, :call_status], name: 'index_users_on_target_call_status'
    
    # Activity counting queries optimization
    add_index :activities, [:trackable_type, :trackable_id, :action], name: 'index_activities_on_trackable_action'
    
    # Activity details lookup optimization
    add_index :activities, [:trackable_type, :trackable_id, :details], name: 'index_activities_on_trackable_details'
    
    # Invoice status queries optimization
    add_index :invoices, [:source_type, :source_id, :status], name: 'index_invoices_on_source_status'
  end
end