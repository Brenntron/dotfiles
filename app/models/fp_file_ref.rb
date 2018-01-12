class FpFileRef < ApplicationRecord
  belongs_to :false_positive
  belongs_to :file_reference
end
