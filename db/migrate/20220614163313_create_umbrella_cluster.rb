class CreateUmbrellaCluster < ActiveRecord::Migration[5.2]
  def change
    create_table :umbrella_clusters, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.string :domain, collation: "utf8mb4_0900_ai_ci"
      t.references :platform, index: true
      t.string :category_ids
      t.integer :status, default: 0
      t.integer :traffic_hits, default: 0
      t.string :comment
      t.timestamps
    end
  end
end
