class CreateClusterAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :cluster_assignments do |t|
      t.belongs_to :user
      t.integer :cluster_id

      t.timestamps
    end
  end
end
