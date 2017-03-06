class AddLinenumberToRules < ActiveRecord::Migration[5.0]
  def change
    add_column :rules, :linenumber, :integer
  end
end
