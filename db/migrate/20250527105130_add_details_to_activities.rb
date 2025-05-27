class AddDetailsToActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :details, :text
  end
end
