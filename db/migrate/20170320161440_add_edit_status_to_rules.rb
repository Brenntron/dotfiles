class AddEditStatusToRules < ActiveRecord::Migration[5.0]
  def change
    add_column :rules, :edit_status, :string, null: false
    add_column :rules, :parse_status, :boolean, null: false, default: true
    add_column :rules, :on_status, :boolean, null: false, default: true
  end
end
