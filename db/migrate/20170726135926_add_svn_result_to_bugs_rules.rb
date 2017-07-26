class AddSvnResultToBugsRules < ActiveRecord::Migration[5.1]
  def change
    execute "ALTER TABLE bugs_rules DROP PRIMARY KEY;"
    add_column :bugs_rules, :id, :primary_key
    add_column :bugs_rules, :svn_result_output, :text
    add_column :bugs_rules, :svn_result_code, :integer
    add_index :bugs_rules, [:bug_id, :rule_id], unique: true
  end
end
