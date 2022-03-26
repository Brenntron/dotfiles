class CreateSenderDomainReputationDisputeAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :sender_domain_reputation_dispute_attachments do |t|
      t.integer        :sender_domain_reputation_dispute_id
      t.integer        :bugzilla_attachment_id
      t.string         :file_name
      t.text           :direct_upload_url
      t.integer        :size
      t.timestamps
    end
  end
end
