class MoreSupportColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :sbrs_score, :float
    change_column :complaint_entries, :wbrs_score, :float
    add_column :complaint_entries, :uri, :text
    add_column :complaint_entries, :suggested_disposition, :string
    add_column :complaint_entries, :ip_address, :string
    add_column :complaints, :submission_type, :string
    add_column :complaints, :submitter_type, :string
    add_column :complaint_entries, :entry_type, :string
  end
end
