class CreateSuppliers < ActiveRecord::Migration[7.1]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.text :supplier_notes
      t.integer :total_orders
      t.string :source

      t.timestamps
    end
  end
end
