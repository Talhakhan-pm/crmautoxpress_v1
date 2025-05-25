class AddSourceToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :source, :string, default: 'callback'
    add_index :products, :source
  end
end
