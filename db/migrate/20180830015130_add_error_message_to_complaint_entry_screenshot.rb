class AddErrorMessageToComplaintEntryScreenshot < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entry_screenshots, :error_message, :string, default: ""
  end
end
