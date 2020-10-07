class AddMultiIpSchema < ActiveRecord::Migration[5.2]
  def change
    add_column :dispute_entries, :proxy_url, :text
    add_column :dispute_entries, :multi_wbrs_threat_category, :text
    add_column :dispute_entries, :wbrs_threat_category, :text
    add_column :dispute_entry_preloads, :multi_wbrs_threat_category, :text
  end
end
