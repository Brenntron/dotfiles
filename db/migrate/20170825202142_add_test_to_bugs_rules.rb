class AddTestToBugsRules < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs_rules, :tested, :boolean
  end
end
