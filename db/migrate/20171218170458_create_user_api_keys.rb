class CreateUserApiKeys < ActiveRecord::Migration[5.1]
  def change
    create_table :user_api_keys do |t|
      t.timestamps
      t.integer :user_id
      t.string :api_key
    end

    add_index :user_api_keys, :api_key, unique: true
  end
end
