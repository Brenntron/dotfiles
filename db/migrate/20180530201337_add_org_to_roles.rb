class AddOrgToRoles < ActiveRecord::Migration[5.1]
  def change
    add_column :roles, :org_subset_id, :integer
  end
end
