class DisputeEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :dispute
end
