class AddCallStatusToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :call_status, :integer, default: 0
    add_column :users, :current_call_id, :string
    add_column :users, :call_started_at, :datetime
    
    add_index :users, :call_status
    add_index :users, :current_call_id
  end
end
