class CreateOrgSubsets < ActiveRecord::Migration[5.1]
  def change
    create_table :org_subsets do |t|
      t.string :name

      t.timestamps
    end
  end
end
