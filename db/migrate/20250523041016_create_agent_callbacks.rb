class CreateAgentCallbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_callbacks do |t|
      t.string :customer_name
      t.string :phone_number
      t.string :car_make_model
      t.integer :year
      t.text :product
      t.string :zip_code
      t.integer :status
      t.date :follow_up_date
      t.string :agent
      t.text :notes

      t.timestamps
    end
  end
end
