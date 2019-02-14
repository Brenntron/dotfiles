class AddBzApiKeyToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :bugzilla_api_key, :string
  end
end
