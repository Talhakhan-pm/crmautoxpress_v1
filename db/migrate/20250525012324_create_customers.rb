class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :phone_number
      t.string :email
      t.text :full_address
      t.string :source_campaign
      t.string :gclid
      t.string :utm_source
      t.string :utm_campaign
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :customers, :phone_number
    add_index :customers, :gclid
  end
end
