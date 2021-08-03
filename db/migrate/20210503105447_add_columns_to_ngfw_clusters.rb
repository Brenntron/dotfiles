class AddColumnsToNgfwClusters < ActiveRecord::Migration[5.2]
  def change
    add_reference :ngfw_clusters, :platform, index: true
    add_column :ngfw_clusters, :category_ids, :string # mysql can't store arrays =(
    add_column :ngfw_clusters, :status, :integer, default: 0
    add_column :ngfw_clusters, :comment, :string
  end
end
