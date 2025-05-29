class AddDispatcherFieldsToRefunds < ActiveRecord::Migration[7.1]
  def change
    add_column :refunds, :dispatcher_decision, :string
    add_column :refunds, :delay_duration, :integer
    add_column :refunds, :additional_cost, :decimal
    add_column :refunds, :agent_instructions, :text
  end
end
