class AddCustomersProductsPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Customers performance indexes
    add_index :customers, :email, name: 'index_customers_on_email'
    add_index :customers, :status, name: 'index_customers_on_status'
    add_index :customers, :source_campaign, name: 'index_customers_on_source_campaign'
    add_index :customers, :created_at, name: 'index_customers_on_created_at'
    add_index :customers, [:status, :created_at], name: 'index_customers_on_status_created_at'
    
    # Products performance indexes  
    add_index :products, :created_at, name: 'index_products_on_created_at'
    add_index :products, [:status, :created_at], name: 'index_products_on_status_created_at'
    add_index :products, [:category, :status], name: 'index_products_on_category_status'
    add_index :products, [:source, :status], name: 'index_products_on_source_status'
    
    # Supplier products performance (for products includes)
    add_index :supplier_products, :product_id, name: 'index_supplier_products_on_product_id' unless index_exists?(:supplier_products, :product_id)
    add_index :supplier_products, [:product_id, :created_at], name: 'index_supplier_products_on_product_created'
  end
end