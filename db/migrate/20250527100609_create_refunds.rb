class CreateRefunds < ActiveRecord::Migration[7.1]
  def change
    create_table :refunds do |t|
      t.references :order, foreign_key: true
      t.integer :processing_agent_id
      t.string :refund_number
      t.datetime :refund_date
      t.string :customer_name
      t.string :customer_email
      t.decimal :original_charge_amount, precision: 10, scale: 2
      t.decimal :refund_amount, precision: 10, scale: 2
      t.integer :refund_stage, default: 0
      t.integer :refund_reason
      t.string :order_status
      t.string :agent_name
      t.text :notes
      t.text :internal_notes
      t.string :payment_processor
      t.string :transaction_id
      t.string :refund_method
      t.text :bank_details
      t.integer :estimated_processing_days, default: 7
      t.datetime :completed_at
      t.string :last_modified_by
      t.integer :priority, default: 1
      t.string :replacement_order_number
      t.string :return_tracking_number
      t.datetime :return_deadline

      t.timestamps
    end
    
    add_foreign_key :refunds, :users, column: :processing_agent_id
    add_index :refunds, :refund_number
    add_index :refunds, :refund_stage
    add_index :refunds, :refund_date
  end
end
