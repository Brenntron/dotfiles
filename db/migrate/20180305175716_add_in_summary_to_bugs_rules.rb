class AddInSummaryToBugsRules < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs_rules, :in_summary, :boolean, default: false
  end
end
