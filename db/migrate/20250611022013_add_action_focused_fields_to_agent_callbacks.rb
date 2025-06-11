class AddActionFocusedFieldsToAgentCallbacks < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_callbacks, :priority_level, :string
    add_column :agent_callbacks, :last_contact_date, :datetime
    add_column :agent_callbacks, :next_action, :string
    
    # Performance indexes for Action-Focused Layout
    add_index :agent_callbacks, :priority_level
    add_index :agent_callbacks, :last_contact_date
    add_index :agent_callbacks, [:priority_level, :follow_up_date]
    add_index :agent_callbacks, [:last_contact_date, :status]
  end
end
