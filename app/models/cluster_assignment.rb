class ClusterAssignment < ApplicationRecord
  belongs_to :user

  EXPIRED_TIMEOUT = 60 # minutes

  class << self
    # all assignments are valid during EXPIRED_TIMEOUT
    # so we need to clear exipred assignments before each action
    # where we select assignments from DB

    def fetch_all_assignments
      destroy_expired_assignments!

      all
    end

    def fetch_assignments_for(user: nil, clusters: nil)
      destroy_expired_assignments!

      return includes(:user).where(cluster_id: clusters) if clusters

      return includes(:user).where(user_id: user.id) if user
    end

    def assign(cluster_ids, user)
      destroy_expired_assignments!

      assignments = where(cluster_id: cluster_ids)
      cluster_ids.each do |cluster_id|
        raise 'Cluster already assigned to someone else' if assignments.find { |a| a.cluster_id == cluster_id.to_i }

        create(cluster_id: cluster_id, user_id: user.id)
      end
    end

    def unassign(cluster_ids, user)
      where(cluster_id: cluster_ids, user_id: user).destroy_all
    end

    private

    def destroy_expired_assignments!
      where('created_at < ?', EXPIRED_TIMEOUT.minutes.ago).destroy_all
    end
  end
end
