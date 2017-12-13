class TypeIndexOnLinks < ActiveRecord::Migration[5.1]
  def change
    remove_index :bug_reference_rule_links, [:link_id, :link_type]
    add_index :bug_reference_rule_links, [:link_type, :link_id]
  end
end
