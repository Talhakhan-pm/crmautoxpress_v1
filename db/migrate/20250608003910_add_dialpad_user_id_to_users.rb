class AddDialpadUserIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :dialpad_user_id, :string
  end
end
