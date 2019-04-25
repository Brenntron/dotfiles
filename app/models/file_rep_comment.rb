class FileRepComment < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  # belongs_to :file_reference
  belongs_to :user
  validates :comment, presence: true

  scope :recent_first, -> {order('created_at DESC')}
end
