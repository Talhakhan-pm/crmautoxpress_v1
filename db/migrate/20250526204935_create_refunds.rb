class CreateRefunds < ActiveRecord::Migration[7.1]
  def change
    create_table :refunds do |t|
      t.references :order, null: false, foreign_key: true
      t.references :dispatch, null: false, foreign_key: true
      t.string :agent_name
      t.string :customer_name
      t.string :customer_email
      t.decimal :charge
      t.decimal :refund_amount
      t.string :refund_stage
      t.string :order_status
      t.integer :processing_agent_id
      t.string :refund_reason
      t.text :order_summary

      t.timestamps
    end
  end
end
