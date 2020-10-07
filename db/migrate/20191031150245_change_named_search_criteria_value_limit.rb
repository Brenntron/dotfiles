class ChangeNamedSearchCriteriaValueLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :named_search_criteria, :value, :text
  end
end
