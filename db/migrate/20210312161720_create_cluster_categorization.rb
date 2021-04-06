class CreateClusterCategorization < ActiveRecord::Migration[5.2]
  def change
    create_table :cluster_categorizations do |t|
      t.belongs_to :user
      t.integer :cluster_id
      t.string :comment
      t.string :category_ids

      t.timestamps
    end
  end
end
