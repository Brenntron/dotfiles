class S3Url < ApplicationRecord
  has_many :false_positive_file_refs, as: :file_ref
  has_many :false_positives, through: :false_positive_file_refs
end
