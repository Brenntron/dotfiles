class AddClusterIdToClusterAssignments < ActiveRecord::Migration[5.2]
  def change
    add_column :cluster_assignments, :cluster_id, :integer
  end
end
