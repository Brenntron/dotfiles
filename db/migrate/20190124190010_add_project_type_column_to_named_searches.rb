class AddProjectTypeColumnToNamedSearches < ActiveRecord::Migration[5.2]
  def change
    add_column :named_searches, :project_type, :string
  end
end
