class CreateMerakiClusters < ActiveRecord::Migration[6.1]
  def change
    create_table :meraki_clusters do |t|
      t.string :domain, collation: "utf8mb4_0900_ai_ci"
      t.references :platform, index: true
      t.string :category_ids
      t.integer :status, default: 0
      t.bigint :traffic_hits, default: 0
      t.string :comment
      t.timestamps
    end
  end
end
