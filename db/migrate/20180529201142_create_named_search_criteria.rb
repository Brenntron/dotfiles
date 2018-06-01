class CreateNamedSearchCriteria < ActiveRecord::Migration[5.1]
  def change
    create_table :named_search_criteria do |t|
      t.timestamps
      t.integer :named_search_id
      t.string :field_name
      t.string :value

    end
  end
end
