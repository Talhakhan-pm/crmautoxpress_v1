class AddWorkflowFieldsToRefunds < ActiveRecord::Migration[7.1]
  def change
    add_column :refunds, :corrected_customer_details, :text
    add_column :refunds, :part_research_notes, :text
    add_column :refunds, :price_difference, :decimal
    add_column :refunds, :alternative_part_name, :string
    add_column :refunds, :alternative_part_price, :decimal
  end
end
