class CreateUserPreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :user_preferences do |t|
      t.belongs_to :user, index: true
      t.string :name
      t.text :value, limit: 65535

      t.timestamps
    end
  end
end
