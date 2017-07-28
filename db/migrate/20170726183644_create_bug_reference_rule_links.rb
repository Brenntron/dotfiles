class CreateBugReferenceRuleLinks < ActiveRecord::Migration[5.1]
  def change
    create_table :bug_reference_rule_links do |t|
      t.integer :reference_id
      t.integer :link_id
      t.string :link_type
      t.timestamps
    end
    add_index :bug_reference_rule_links, [:link_id,:link_type]
  end
end
