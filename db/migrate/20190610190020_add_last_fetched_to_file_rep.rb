class AddLastFetchedToFileRep < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :last_fetched, :datetime
    rename_column :file_reputation_disputes, :detection_created_at, :detection_last_set
  end
end