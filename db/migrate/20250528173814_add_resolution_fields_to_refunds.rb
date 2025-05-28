class AddResolutionFieldsToRefunds < ActiveRecord::Migration[7.1]
  def change
    # Check if columns exist before adding them
    add_column :refunds, :resolution_stage, :integer unless column_exists?(:refunds, :resolution_stage)
    add_column :refunds, :agent_notes, :text unless column_exists?(:refunds, :agent_notes)
    add_column :refunds, :dispatcher_notes, :text unless column_exists?(:refunds, :dispatcher_notes)
    add_column :refunds, :customer_response, :text unless column_exists?(:refunds, :customer_response)
  end
end
