class AddProductToSavedSearches < ActiveRecord::Migration[5.1]
  def change
    add_column :saved_searches, :product, :string
  end
end
