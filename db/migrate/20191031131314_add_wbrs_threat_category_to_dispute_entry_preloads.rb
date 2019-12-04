class AddWbrsThreatCategoryToDisputeEntryPreloads < ActiveRecord::Migration[5.2]
  def change
    add_column :dispute_entry_preloads, :wbrs_threat_category, :text
  end
end
