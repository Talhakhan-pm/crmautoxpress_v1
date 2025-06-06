class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, foreign_key: true
      t.references :communication, foreign_key: true
      t.references :agent_callback, foreign_key: true
      t.string :notification_type, default: 'new_communication'
      t.datetime :read_at

      t.timestamps
    end
    
    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, [:user_id, :created_at]
  end
end
