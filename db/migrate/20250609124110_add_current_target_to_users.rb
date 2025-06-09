class AddCurrentTargetToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :current_target_type, :string
    add_column :users, :current_target_id, :integer

    # Add indexes for performance
    add_index :users, :current_target_type
    add_index :users, :current_target_id
    add_index :users, [:current_target_type, :current_target_id], name: 'index_users_on_current_target'
  end
end
