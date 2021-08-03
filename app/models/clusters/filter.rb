class Clusters::Filter
  attr_accessor :clusters, :filter_hash, :user

  def initialize(clusters, filter, user)
    @clusters = clusters.dup
    @filter_hash = filter
    @user = user
  end

  def filter
    # user specific filters - filters, selected by users
    case filter_hash[:f]
    when 'all'
      clusters
    when 'my'
      filter_assigned_to_user
    when 'unassigned'
      filter_unassigned
    when 'pending'
      filter_pending
    else
      filter_by_default
    end

    clusters
  end

  private

  def filter_assigned_to_user
    clusters.select! do |cluster|
      cluster_assigned_to_user?(cluster)
    end
  end

  def filter_unassigned
    clusters.filter! do |cluster|
      cluster_unassigned?(cluster)
    end
  end

  def filter_pending
    clusters.filter! do |cluster|
      cluster[:is_pending]
    end
  end

  def filter_by_default
    # assigned to user + unassigned
    clusters.filter! do |cluster|
      cluster_unassigned?(cluster) || cluster_assigned_to_user?(cluster)
    end
  end

  def cluster_assigned_to_user?(cluster)
    cluster[:assigned_to] == user.cvs_username
  end

  def cluster_unassigned?(cluster)
    cluster[:assigned_to].blank?
  end

  def cluster_pending?(cluster, pending_clusters)
    pending_clusters.find { |pending_cluster| pending_cluster.cluster_id == cluster[:cluster_id].to_i }.present?
  end
end
