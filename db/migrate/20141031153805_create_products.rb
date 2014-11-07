class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :title
      t.decimal :price
      t.string :description
      t.boolean :isOnSale
      t.string :image
      t.integer :contact_id
      t.timestamps
    end
  end
end
