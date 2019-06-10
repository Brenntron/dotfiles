class AddLastFetchedToFileRep < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :last_fetched, :datetime
  end
end