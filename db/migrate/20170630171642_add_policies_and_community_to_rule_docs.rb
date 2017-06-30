class AddPoliciesAndCommunityToRuleDocs < ActiveRecord::Migration[5.1]
  def up
    add_column :rule_docs, :policies, :text
    add_column :rule_docs, :is_community, :boolean
  end

  def down
    remove_column :rule_docs, :policies
    remove_column :rule_docs, :is_community
  end
end
