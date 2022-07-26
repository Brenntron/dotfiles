class AddEmailDataToSdr < ActiveRecord::Migration[5.2]
  def up
    add_column :sender_domain_reputation_dispute_attachments, :email_header_data, :text
  end

  def down
    remove_column :sender_domain_reputation_dispute_attachments, :email_header_data, :text
  end
end
