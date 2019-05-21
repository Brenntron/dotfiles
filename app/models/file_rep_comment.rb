class FileRepComment < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :file_reputation_dispute
  belongs_to :user
  validates :comment, presence: true

  scope :recent_first, -> {order('created_at DESC')}

  def self.create_action(comment, dispute_id, current_user)
    FileRepComment.create!(comment: comment, file_reputation_dispute_id: dispute_id, user_id: current_user.id)
  end
end
