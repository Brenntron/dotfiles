class AttachmentSerializer < ActiveModel::Serializer
  attributes :id, :bugzilla_attachment_id, :file_name, :direct_upload_url, :size, :bug_id, :creator, :summary, :is_obsolete, :is_private, :content_type
end
