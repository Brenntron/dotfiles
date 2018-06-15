class CreateCustomers < ActiveRecord::Migration[5.1]
  def change
    create_table :customers do |t|
      t.integer :company_id
      t.string :name
      t.string :email
      t.string :phone

      t.timestamps
      t.index :company_id
    end
  end
end
