class FileReference < ApplicationRecord
  has_many :false_positive_file_refs, as: :file_ref
  has_many :false_positives, through: :false_positive_file_refs

  scope :s3_urls, -> { where(type: 'S3Url') }
  scope :local_files, -> { where(type: 'LocalFile') }
end
