class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.references :trackable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.string :field_changed
      t.text :old_value
      t.text :new_value
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end
  end
end
