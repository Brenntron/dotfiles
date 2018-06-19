class CreateDisputeEmailAttachments < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_email_attachments do |t|
      t.integer          :dispute_email_id
      t.integer          :bugzilla_attachment_id
      t.string           :file_name
      t.text             :direct_upload_url
      t.integer          :size
      t.timestamps
    end
  end
end
