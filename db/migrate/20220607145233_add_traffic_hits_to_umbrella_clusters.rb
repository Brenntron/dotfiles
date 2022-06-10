class AddTrafficHitsToUmbrellaClusters < ActiveRecord::Migration[5.2]
  def change
    add_column :umbrella_clusters, :traffic_hits, :integer, default: 0
  end
end
