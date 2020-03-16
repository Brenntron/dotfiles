class AddIpsToDisputeEntries < ActiveRecord::Migration[5.2]
  def up
    add_column :dispute_entries, :web_ips, :text
    add_column :dispute_rule_hits, :is_multi_ip_rulehit, :boolean
  end

  def down
    remove_column :dispute_entries, :web_ips
    remove_column :dispute_rule_hits, :is_multi_ip_rulehit
  end
end
