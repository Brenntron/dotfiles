class CreateComplaintEntryCredits < ActiveRecord::Migration[5.2]
  def change
    create_table :complaint_entry_credits do |t|
      t.string :credit
      t.belongs_to :user
      t.belongs_to :complaint_entry

      t.timestamps
    end
  end
end
