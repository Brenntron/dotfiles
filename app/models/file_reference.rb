class FileReference < ApplicationRecord
  has_one :fp_file_ref
  has_one :false_positive, through: :fp_file_ref

  scope :s3_urls, -> { where(type: 'S3Url') }
  scope :local_files, -> { where(type: 'LocalFile') }
end
