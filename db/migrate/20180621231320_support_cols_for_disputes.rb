class SupportColsForDisputes < ActiveRecord::Migration[5.1]
  def change
    change_column :dispute_entries, :uri, :text
    add_column :disputes, :submission_type, :string
    add_column :disputes, :submitter_type, :string
    add_column :dispute_entries, :sbrs_score, :float
    add_column :dispute_entries, :wbrs_score, :float 
  end
end
