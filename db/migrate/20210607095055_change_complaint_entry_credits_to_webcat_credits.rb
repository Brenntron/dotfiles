class ChangeComplaintEntryCreditsToWebcatCredits < ActiveRecord::Migration[5.2]
  def up
    rename_table :complaint_entry_credits, :webcat_credits
    add_column :webcat_credits, :type, :string
    add_column :webcat_credits, :domain, :string, collation: "utf8mb4_0900_ai_ci"

    WebcatCredit.update_all(type: 'ComplaintEntryCredit')
  end

  def down
    remove_column :webcat_credits, :type
    remove_column :webcat_credits, :domain
    rename_table :webcat_credits, :complaint_entry_credits
  end
end
