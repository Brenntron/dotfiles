class CreatePlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :platforms do |t|
      t.string :public_name
      t.string :internal_name
      t.boolean :webrep, null: false
      t.boolean :emailrep, null: false
      t.boolean :webcat, null: false
      t.boolean :filerep, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
  end
end
