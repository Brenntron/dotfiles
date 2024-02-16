class ChangeIntegerLimitInUmbrellaClusters < ActiveRecord::Migration[6.1]
  def change
      change_column :umbrella_clusters, :traffic_hits, :integer, limit: 8
  end
end
