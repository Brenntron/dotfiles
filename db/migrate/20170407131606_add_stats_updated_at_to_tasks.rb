class AddStatsUpdatedAtToTasks < ActiveRecord::Migration[5.0]
  def change
    add_column :tasks, :stats_updated_at, :datetime
  end
end
