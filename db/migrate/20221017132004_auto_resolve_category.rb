class AutoResolveCategory < ActiveRecord::Migration[5.2]
  def up
    add_column :dispute_entries, :auto_resolve_category, :string
  end

  def down
    remove_column :dispute_entries, :auto_resolve_category, :string
  end
end
