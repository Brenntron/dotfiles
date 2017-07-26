class AddSvnResultToBugsRules < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs_rules, :svn_result_output, :string
    add_column :bugs_rules, :svn_result_code, :integer
    add_index :bugs_rules, [:bug_id, :rule_id], unique: true
  end
end
