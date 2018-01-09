class FalsePositiveFileRef < ApplicationRecord
  belongs_to :false_positive
  belongs_to :file_ref, polymorphic: true
end
