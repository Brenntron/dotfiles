class ClusterCategorization < ApplicationRecord
  belongs_to :user

  def self.get_categorized_cluster_ids_for(user)
    where(user_id: user.id).pluck(:cluster_id)
  end
end
