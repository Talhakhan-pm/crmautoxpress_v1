class AddPolymorphicSourceToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_reference :invoices, :source, polymorphic: true, null: true, index: true
  end
end
