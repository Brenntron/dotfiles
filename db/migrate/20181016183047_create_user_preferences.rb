class CreateUserPreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :user_preferences do |t|
      t.integer :user_id
      t.string :name
      t.text :value, limit: 65535

      t.timestamps
    end
    add_index :user_preferences, ["user_id", 'name']
  end
end
