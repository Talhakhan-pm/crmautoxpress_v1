class RemoveSupplierFieldsFromDispatches < ActiveRecord::Migration[7.1]
  def change
    remove_column :dispatches, :supplier_name, :string
    remove_column :dispatches, :supplier_order_number, :string
    remove_column :dispatches, :supplier_cost, :decimal
    remove_column :dispatches, :supplier_shipment_proof, :string
  end
end
