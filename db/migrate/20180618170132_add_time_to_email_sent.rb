class AddTimeToEmailSent < ActiveRecord::Migration[5.1]
  def up
    add_column :dispute_emails, :email_sent_at, :datetime 
  end

  def down
    remove_column :dispute_emails, :email_sent_at
  end
end
