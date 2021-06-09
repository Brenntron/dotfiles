class AddPermamentToClusterAssignments < ActiveRecord::Migration[5.2]
  def change
    add_column :cluster_assignments, :permanent, :boolean, default: false
  end
end
