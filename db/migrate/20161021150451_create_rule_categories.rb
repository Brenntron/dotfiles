class CreateRuleCategories < ActiveRecord::Migration
  def change
    create_table :rule_categories do |t|
      t.string :category

      t.timestamps
    end
  end
end
