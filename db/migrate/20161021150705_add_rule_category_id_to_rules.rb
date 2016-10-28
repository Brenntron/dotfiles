class AddRuleCategoryIdToRules < ActiveRecord::Migration
  def change
    add_column :rules, :rule_category_id, :integer
  end
end
