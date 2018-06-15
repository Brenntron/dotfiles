class AddCustomerIdToComplaints < ActiveRecord::Migration[5.1]
  def change
    add_column :complaints, :customer_id, :integer
    add_index :complaints, :customer_id

    remove_column :complaints, :customer, :string
  end
end
