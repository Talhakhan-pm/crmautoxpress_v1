class RemoveBusinessEmailDatabaseDefault < ActiveRecord::Migration[7.1]
  def change
    # Remove the stupid database-level default for business_email
    change_column_default :invoices, :business_email, from: 'khan@autoxpress.us', to: nil
  end
end
