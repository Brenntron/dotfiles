class AddThreatCatToEntries < ActiveRecord::Migration[5.2]
  def up
    add_column :dispute_entries, :suggested_threat_category, :text
  end

  def down
    remove_column :dispute_entries, :suggested_threat_category, :text
  end
end
