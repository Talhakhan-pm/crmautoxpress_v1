class AddDialpadUserIdIndex < ActiveRecord::Migration[7.1]
  def change
    # CRITICAL: Index for dialpad_user_id lookups (every webhook uses this)
    # This field exists but has no index, causing full table scans
    add_index :users, :dialpad_user_id, unique: true, where: "dialpad_user_id IS NOT NULL"
    
    # Performance: Composite index for dashboard card queries that check:
    # current_target_type='callback' AND current_target_id=X AND call_status IN ('calling','on_call')
    add_index :users, [:current_target_type, :current_target_id, :call_status], 
              name: 'index_users_on_target_and_call_status'
  end
end
