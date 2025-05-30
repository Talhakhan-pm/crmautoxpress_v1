class AddReplacementLinkingToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :original_order_id, :integer
    add_column :orders, :replacement_order_id, :integer
    add_column :orders, :replacement_reason, :string
    
    add_index :orders, :original_order_id
    add_index :orders, :replacement_order_id
  end
end
