class AddSupplierFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :supplier, foreign_key: true
    add_column :orders, :supplier_order_number, :string
    add_column :orders, :supplier_cost, :decimal, precision: 10, scale: 2
    add_column :orders, :supplier_shipment_proof, :string
    add_column :orders, :estimated_delivery_date, :date
    add_column :orders, :actual_delivery_date, :date
    add_column :orders, :quality_rating, :integer
    add_column :orders, :part_link, :string
    add_column :orders, :part_price, :decimal, precision: 10, scale: 2
    add_column :orders, :supplier_shipping_cost, :decimal, precision: 8, scale: 2
    add_column :orders, :supplier_tax, :decimal, precision: 8, scale: 2
  end
end
