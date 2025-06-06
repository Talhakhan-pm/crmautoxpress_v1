class CreateCommunications < ActiveRecord::Migration[7.1]
  def change
    create_table :communications do |t|
      t.references :agent_callback, foreign_key: true
      t.references :user, foreign_key: true
      t.text :content
      t.string :message_type, default: 'note'
      t.boolean :is_urgent, default: false
      t.text :mentions
      t.references :parent_communication, null: true, foreign_key: { to_table: :communications }

      t.timestamps
    end
    
    add_index :communications, :created_at
    add_index :communications, [:agent_callback_id, :created_at]
  end
end
