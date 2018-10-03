class DisputeComment < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :dispute
  belongs_to :user
  validates :comment, presence: true

  scope :recent_first, -> {order('created_at DESC')}
end
