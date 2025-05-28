class AddResolutionFieldsToRefunds < ActiveRecord::Migration[7.1]
  def change
    add_column :refunds, :resolution_stage, :integer
    add_column :refunds, :agent_notes, :text
    add_column :refunds, :dispatcher_notes, :text
    add_column :refunds, :customer_response, :text
  end
end
