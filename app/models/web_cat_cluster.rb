class WebCatCluster < ApplicationRecord
  belongs_to :platform

  enum status: { created: 0, pending: 1, processed: 2 }

  scope :visible, -> { where.not(status: :processed) }
  scope :meraki, -> { where(cluster_type: 'Meraki') }
  scope :ngfw, -> { where(cluster_type: 'NGFW') }
  scope :umbrella, -> { where(cluster_type: 'Umbrella') }
end