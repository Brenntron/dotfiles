class WebCatCluster < ApplicationRecord
  belongs_to :platform
  has_many :cluster_assignments, foreign_key: 'domain', primary_key: 'domain', dependent: :destroy

  enum status: { created: 0, pending: 1, processed: 2 }

  scope :visible, -> { where.not(status: :processed) }
  scope :meraki, -> { where(cluster_type: 'Meraki') }
  scope :ngfw, -> { where(cluster_type: 'NGFW') }
  scope :umbrella, -> { where(cluster_type: 'Umbrella') }
  scope :sorted_by_user, ->(sort_order) do
    joins("LEFT OUTER JOIN cluster_assignments ON web_cat_clusters.domain = cluster_assignments.domain")
      .joins("LEFT OUTER JOIN users ON cluster_assignments.user_id = users.id")
      .order(Arel.sql("COALESCE(users.cvs_username, '') #{sort_order}"))
  end
end