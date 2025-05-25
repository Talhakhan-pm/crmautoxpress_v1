class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.string :order_number
      t.datetime :order_date
      t.string :customer_name
      t.text :customer_address
      t.string :customer_phone
      t.string :customer_email
      t.string :product_name
      t.integer :car_year
      t.string :car_make_model
      t.integer :order_status
      t.decimal :product_price, precision: 10, scale: 2
      t.decimal :tax_amount, precision: 8, scale: 2
      t.decimal :shipping_cost, precision: 8, scale: 2
      t.decimal :total_amount, precision: 10, scale: 2
      t.string :tracking_number
      t.string :product_link
      t.date :estimated_delivery
      t.text :comments
      t.text :internal_notes
      t.string :last_modified_by
      t.integer :agent_callback_id
      t.integer :customer_id
      t.integer :product_id
      t.integer :agent_id
      t.integer :processing_agent_id
      t.integer :priority, default: 1
      t.string :source_channel
      t.integer :warranty_period_days, default: 30
      t.text :warranty_terms
      t.integer :return_window_days, default: 14
      t.decimal :commission_amount, precision: 8, scale: 2

      t.timestamps
    end
    
    add_index :orders, :order_number, unique: true
    add_index :orders, :order_status
    add_index :orders, :agent_id
    add_index :orders, :customer_id
    add_index :orders, :product_id
    add_index :orders, :agent_callback_id
    add_index :orders, :order_date
    add_index :orders, :priority
  end
end
