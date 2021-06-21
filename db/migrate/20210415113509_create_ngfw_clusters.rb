class CreateNgfwClusters < ActiveRecord::Migration[5.2]
  def change
    create_table :ngfw_clusters, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.string :domain, collation: "utf8mb4_0900_ai_ci"
      t.integer :traffic_hits

      t.timestamps
    end
  end
end
