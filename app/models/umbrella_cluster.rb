class UmbrellaCluster < ApplicationRecord
  belongs_to :platform

  enum status: { created: 0, pending: 1, processed: 2 }

  scope :visible, -> { where.not(status: :processed) }
end
