class AddCommunicationCounterCache < ActiveRecord::Migration[7.1]
  def change
    # Add counter cache column for communications count
    add_column :agent_callbacks, :communications_count, :integer, default: 0
    
    # Add index for better performance on counter cache column
    add_index :agent_callbacks, :communications_count
  end
end
