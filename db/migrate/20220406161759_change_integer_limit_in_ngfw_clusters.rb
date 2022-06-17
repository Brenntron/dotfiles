class ChangeIntegerLimitInNgfwClusters < ActiveRecord::Migration[5.2]
  def change
    change_column :ngfw_clusters, :traffic_hits, :integer, limit: 8
  end
end
