class AddComprehensivePerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Critical AgentCallback performance indexes (fixes 7+ second dashboard queries)
    add_index :agent_callbacks, [:created_at, :status], name: 'index_agent_callbacks_on_created_at_and_status'
    add_index :agent_callbacks, [:status, :follow_up_date], name: 'index_agent_callbacks_on_status_and_follow_up_date'
    add_index :agent_callbacks, [:user_id, :created_at], name: 'index_agent_callbacks_on_user_id_and_created_at'
    add_index :agent_callbacks, :car_make_model, name: 'index_agent_callbacks_on_car_make_model'
    
    # Activity performance indexes (fixes slow timeline loading)
    add_index :activities, [:trackable_type, :trackable_id, :created_at], name: 'index_activities_on_trackable_and_created_at'
    add_index :activities, [:user_id, :created_at], name: 'index_activities_on_user_id_and_created_at'
    
    # Order performance indexes
    add_index :orders, [:created_at, :order_status], name: 'index_orders_on_created_at_and_status'
    add_index :orders, [:agent_id, :created_at], name: 'index_orders_on_agent_id_and_created_at'
    add_index :orders, [:processing_agent_id, :created_at], name: 'index_orders_on_processing_agent_and_created_at'
    add_index :orders, :customer_name, name: 'index_orders_on_customer_name'
    
    # Communication performance indexes
    add_index :communications, [:user_id, :created_at], name: 'index_communications_on_user_and_created_at'
    add_index :communications, :message_type, name: 'index_communications_on_message_type'
    
    # Notification performance indexes
    add_index :notifications, [:notification_type, :created_at], name: 'index_notifications_on_type_and_created_at'
    add_index :notifications, [:user_id, :notification_type, :read_at], name: 'index_notifications_on_user_type_read'
    
    # Search optimization indexes
    add_index :customers, :name, name: 'index_customers_on_name'
    add_index :products, :name, name: 'index_products_on_name'
    
    # Additional performance indexes for common queries
    add_index :refunds, [:created_at, :refund_stage], name: 'index_refunds_on_created_at_and_stage'
    add_index :dispatches, [:created_at, :dispatch_status], name: 'index_dispatches_on_created_at_and_status'
  end
end