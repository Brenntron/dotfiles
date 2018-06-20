class AddCustomerIdToDisputes < ActiveRecord::Migration[5.1]
  def change
    add_column :disputes, :customer_id, :integer
    add_index :disputes, :customer_id

    remove_column :disputes, :customer_name, :string
    remove_column :disputes, :customer_email, :string
    remove_column :disputes, :customer_phone, :string
    remove_column :disputes, :customer_company_name, :string
  end
end
