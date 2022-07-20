class CreateUmbrellaCluster < ActiveRecord::Migration[5.2]
  def change
    create_table :umbrella_clusters, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string :domain, collation: "utf8_general_ci"
      t.references :platform, index: true
      t.string :category_ids
      t.integer :status, default: 0
      t.integer :traffic_hits, default: 0
      t.string :comment
      t.timestamps
    end
  end
end
