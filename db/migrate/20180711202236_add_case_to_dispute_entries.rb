class AddCaseToDisputeEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :dispute_entries, :case_opened_at, :datetime
    add_column :dispute_entries, :case_closed_at, :datetime
    add_column :dispute_entries, :case_accepted_at, :datetime
    add_column :dispute_entries, :case_resolved_at, :datetime
  end
end
