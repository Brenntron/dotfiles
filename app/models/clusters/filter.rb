class Clusters::Filter
  attr_accessor :clusters, :filter_hash, :user

  def initialize(clusters, filter, user)
    @clusters = clusters.dup
    @filter_hash = filter
    @user = user
  end

  def filter
    # user specific filters - filters, selected by users
    # 'my' and 'pending' filters applied in DataFetcher's for better performance
    case filter_hash[:f]
    when 'all'
      clusters
    when 'pending'
      clusters
    when 'unassigned'
      filter_unassigned
    else
      filter_by_default
    end

    clusters
  end

  private

  def filter_unassigned
    clusters.filter! do |cluster|
      cluster_unassigned?(cluster)
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
end
