class BugsRules < ActiveRecord::Migration
  def change
    create_table :bugs_rules, id: false do |t|
      t.integer :bug_id
      t.integer :rule_id
    end
  end
end
