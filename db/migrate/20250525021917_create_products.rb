class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number
      t.string :oem_part_number
      t.text :description
      t.string :category
      t.string :vendor_name
      t.decimal :vendor_cost, precision: 10, scale: 2
      t.decimal :selling_price, precision: 10, scale: 2
      t.integer :lead_time_days
      t.text :vehicle_compatibility
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :products, :part_number
    add_index :products, :category
    add_index :products, :status
  end
end
