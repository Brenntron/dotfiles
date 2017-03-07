class AddFilenameToRules < ActiveRecord::Migration[5.0]
  def change
    add_column :rules, :filename, :string
  end
end
