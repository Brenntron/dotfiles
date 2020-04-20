class AddUriAsCategorizedToComplaintEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :complaint_entries, :uri_as_categorized, :text
  end
end
