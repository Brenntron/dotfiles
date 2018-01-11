class FalsePositive < ApplicationRecord
  has_many :false_positive_file_refs
  has_many :s3_urls, through: :false_positive_file_refs, source: :file_ref, source_type: S3Url

  def file_refs
    false_positive_file_refs.map {|link| link.file_ref}
  end

  def save_attachments_from_params(attachments_attrs:)
    attachments_attrs.each do |s3_params|
      s3 = S3Url.create!(s3_params.permit("file_name", "url", "file_type_name"))
      false_positive_file_refs.create(file_ref: s3)
    end

    self
  end

  def self.create_from_params(attrs, attachments_attrs:, sender:)
    if where(source_authority: sender, source_key: attrs['source_key']).exists?
      where(source_authority: sender, source_key: attrs['source_key']).delete_all
    end
    create(attrs.merge(source_authority: sender)).tap do |false_positive|
      false_positive.save_attachments_from_params(attachments_attrs: attachments_attrs)
    end
  end
end
