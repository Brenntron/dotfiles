class CreateNamedSearches < ActiveRecord::Migration[5.1]
  def change
    create_table :named_searches do |t|
      t.timestamps
      t.integer :user_id
      t.string :name

    end
  end
end
