class CreateSavedSearches < ActiveRecord::Migration[5.1]
  def change
    create_table :saved_searches do |t|
      t.text          :session_query
      t.text          :session_search
      t.string        :name
      t.integer       :user_id
      t.timestamps
    end
  end
end
