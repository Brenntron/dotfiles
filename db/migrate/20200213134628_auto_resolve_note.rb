class AutoResolveNote < ActiveRecord::Migration[5.2]
  def up
    add_column :file_reputation_disputes, :auto_resolve_log, :text
    add_column :dispute_entries, :auto_resolve_log, :text
  end

  def down
    remove_column :file_reputation_disputes, :auto_resolve_log, :text
    remove_column :dispute_entries, :auto_resolve_log, :text
  end
end
