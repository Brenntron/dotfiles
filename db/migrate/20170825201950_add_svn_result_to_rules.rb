class AddSvnResultToRules < ActiveRecord::Migration[5.1]
  def change
    add_column :rules, :svn_result_output, :text
    add_column :rules, :svn_result_code, :integer
    add_column :rules, :svn_success, :boolean
  end
end
