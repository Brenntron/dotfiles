class DisputeComment < ApplicationRecord
  belongs_to :dispute
  belongs_to :user

  scope :recent_first, -> {order('created_at DESC')}
end
