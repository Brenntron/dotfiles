class CreateWebCatClusters < ActiveRecord::Migration[6.1]
  def change
    create_table :web_cat_clusters do |t|
      t.string :domain
      t.integer :platform_id
      t.string :category_ids
      t.integer :status, default: 0
      t.integer :traffic_hits, default: 0
      t.string :comment
      t.string :cluster_type
      t.timestamps
    end
    
    add_index :web_cat_clusters, :cluster_type
  end
end
