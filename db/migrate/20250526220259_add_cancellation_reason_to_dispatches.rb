class AddCancellationReasonToDispatches < ActiveRecord::Migration[7.1]
  def change
    add_column :dispatches, :cancellation_reason, :string
  end
end
