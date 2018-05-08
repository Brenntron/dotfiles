class AddFatalErrorsToRules < ActiveRecord::Migration[5.1]
  def change
    add_column :rules, :fatal_errors, :string
  end
end
