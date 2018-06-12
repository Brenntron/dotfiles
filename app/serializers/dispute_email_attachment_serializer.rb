class DisputeEmailAttachmentSerializer < ActiveModel::Serializer
  attributes :id, :dispute_email_id, :bugzilla_attachment_id, :file_name, :direct_upload_url, :size, :created_at
end