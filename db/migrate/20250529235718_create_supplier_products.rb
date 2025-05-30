class CreateSupplierProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :supplier_products do |t|
      t.references :supplier, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :supplier_cost, precision: 10, scale: 2
      t.string :supplier_part_number
      t.integer :lead_time_days
      t.boolean :preferred_supplier, default: false
      t.date :last_quoted_date

      t.timestamps
    end
    
    add_index :supplier_products, [:supplier_id, :product_id], unique: true
  end
end
