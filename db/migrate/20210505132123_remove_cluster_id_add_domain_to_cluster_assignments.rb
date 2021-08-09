class RemoveClusterIdAddDomainToClusterAssignments < ActiveRecord::Migration[5.2]
  def change
    remove_column :cluster_assignments, :cluster_id, :integer
    add_column :cluster_assignments, :domain, :string
  end
end
