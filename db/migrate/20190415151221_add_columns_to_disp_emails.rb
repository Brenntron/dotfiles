class AddColumnsToDispEmails < ActiveRecord::Migration[5.2]
  def change
    add_column :dispute_emails, :file_reputation_dispute_id, :integer, null: true
  end
end
