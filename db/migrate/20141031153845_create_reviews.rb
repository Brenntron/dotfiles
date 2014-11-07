class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.text :text
      t.datetime :reviewedAt
      t.integer :rating
      t.integer :product_id
      t.timestamps
    end
  end
end
