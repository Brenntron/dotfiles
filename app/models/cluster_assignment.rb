class ClusterAssignment < ApplicationRecord
  belongs_to :user

  EXPIRED_TIMEOUT = 60 # minutes

  scope :temporary, -> { where(permanent: false) }

  class << self
    # all assignments are valid during EXPIRED_TIMEOUT
    # so we need to clear exipred assignments before each action
    # where we select assignments from DB

    def fetch_all_assignments
      destroy_expired_assignments!

      all
    end

    def fetch_assignments_for(user: nil, domains: nil)
      destroy_expired_assignments!

      return includes(:user).where(domain: domains) if domains

      return includes(:user).where(user_id: user.id) if user
    end

    def assign(cluster, user)
      destroy_expired_assignments!

      assignments = where(domain: cluster[:domain])
      raise 'Cluster already assigned to someone else' if assignments.any?

      create(domain: cluster[:domain], cluster_id: cluster[:cluster_id].to_i, user_id: user.id)
    end

    def assign!(cluster, user)
      destroy_expired_assignments!
      where(domain: cluster[:domain]).destroy_all
      create(domain: cluster[:domain], cluster_id: cluster[:cluster_id].to_i, user_id: user.id)
    end

    def assign_permanent!(cluster, user)
      destroy_expired_assignments!
      where(domain: cluster[:domain]).destroy_all
      create(domain: cluster[:domain], cluster_id: cluster[:cluster_id].to_i, user_id: user.id, permanent: true)
    end

    def unassign(cluster, user)
      where(domain: cluster[:domain], user_id: user).destroy_all
    end

    def get_assigned_cluster_ids_for(user)
      where(user_id: user.id).pluck(:cluster_id)
    end

    def get_assigned_cluster_domains_for(user)
      where(user_id: user.id).pluck(:domain)
    end

    private

    def destroy_expired_assignments!
      temporary.where('created_at < ?', EXPIRED_TIMEOUT.minutes.ago).destroy_all
    end
  end
end
