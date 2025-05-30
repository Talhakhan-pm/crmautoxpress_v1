class AddReturnFieldsToRefunds < ActiveRecord::Migration[7.1]
  def change
    add_column :refunds, :return_status, :integer, default: 0
    add_column :refunds, :return_carrier, :string
    add_column :refunds, :return_label_url, :text
    add_column :refunds, :return_notes, :text
    add_column :refunds, :return_authorized_at, :datetime
    add_column :refunds, :return_shipped_at, :datetime
    add_column :refunds, :return_received_at, :datetime
    
    add_index :refunds, :return_status
  end
end
