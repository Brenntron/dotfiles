class WebcatDupe < ActiveRecord::Migration[6.1]
  def up
    add_column :complaint_entries, :canonical_id, :integer
  end

  def down
    remove_column :complaint_entries, :canonical_id, :integer
  end
end
