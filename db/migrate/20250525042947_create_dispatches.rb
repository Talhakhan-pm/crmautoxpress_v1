class CreateDispatches < ActiveRecord::Migration[7.1]
  def change
    create_table :dispatches do |t|
      t.integer :order_id
      t.string :order_number
      t.string :customer_name
      t.text :customer_address
      t.string :product_name
      t.string :car_details
      t.string :condition, default: 'new'
      t.string :payment_processor
      t.integer :payment_status, default: 0
      t.integer :processing_agent_id
      t.string :supplier_name
      t.string :supplier_order_number
      t.decimal :supplier_cost, precision: 10, scale: 2
      t.string :supplier_shipment_proof
      t.decimal :product_cost, precision: 10, scale: 2
      t.decimal :tax_amount, precision: 8, scale: 2
      t.decimal :shipping_cost, precision: 8, scale: 2
      t.decimal :total_cost, precision: 10, scale: 2
      t.string :tracking_number
      t.string :tracking_link
      t.integer :shipment_status, default: 0
      t.integer :dispatch_status, default: 0
      t.text :comments
      t.text :internal_notes
      t.string :last_modified_by

      t.timestamps
    end
    
    add_index :dispatches, :order_id, unique: true
    add_index :dispatches, :order_number
    add_index :dispatches, :dispatch_status
    add_index :dispatches, :shipment_status
    add_index :dispatches, :payment_status
    add_index :dispatches, :processing_agent_id
    add_index :dispatches, :supplier_name
  end
end
