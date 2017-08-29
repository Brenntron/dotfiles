class AddDocStatusToRules < ActiveRecord::Migration[5.1]
  def change
    add_column :rules, :doc_status, :string, null: false, default: 'New'
  end
end
