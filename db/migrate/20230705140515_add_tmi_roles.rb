class AddTmiRoles < ActiveRecord::Migration[6.1]
  def change
    Role.create(role: 'tmi viewer', org_subset_id: OrgSubset.where(name: 'webcat').first.id)
    Role.create(role: 'tmi manager', org_subset_id: OrgSubset.where(name: 'webcat').first.id)
  end
end
