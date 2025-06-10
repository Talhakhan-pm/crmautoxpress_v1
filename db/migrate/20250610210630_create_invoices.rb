class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      # Association with agent_callback
      t.references :agent_callback, null: true, foreign_key: true
      
      # PayPal specific fields
      t.string :paypal_invoice_id
      t.string :paypal_invoice_url
      t.string :invoice_number
      t.string :status, default: 'draft'
      
      # Invoice details
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency, default: 'USD'
      t.text :description
      t.text :memo
      
      # Business information
      t.string :business_name, default: 'AutoXpress'
      t.string :business_email, default: 'khan@autoxpress.us'
      
      # Customer information
      t.string :customer_name
      t.string :customer_email
      t.string :customer_phone
      
      # Billing address
      t.string :billing_address_line1
      t.string :billing_address_line2
      t.string :billing_city
      t.string :billing_state
      t.string :billing_postal_code
      t.string :billing_country, default: 'US'
      
      # Shipping address (if different)
      t.string :shipping_address_line1
      t.string :shipping_address_line2
      t.string :shipping_city
      t.string :shipping_state
      t.string :shipping_postal_code
      t.string :shipping_country, default: 'US'
      
      # Payment tracking
      t.datetime :due_date
      t.datetime :paid_date
      t.string :payment_method
      
      # Raw PayPal response data (for debugging/reference)
      t.text :paypal_response_data
      
      t.timestamps
    end
    
    add_index :invoices, :paypal_invoice_id
    add_index :invoices, :status
    add_index :invoices, :customer_email
  end
end
