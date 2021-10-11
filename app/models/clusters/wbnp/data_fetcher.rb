class Clusters::Wbnp::DataFetcher < Clusters::Templates::DataFetcher
  attr_accessor :regex, :filter, :user

  DATA_PATFORM = 'WSA'.freeze

  def initialize(regex, filter, user)
    @regex = regex
    @filter = filter
    @user = user
  end

  def fetch
    parse_response(fetch_data)
  end

  private

  def fetch_data
    conditions = {}
    conditions[:regex] = regex if regex.present?
    # TODO: add template method for 'fetch' method
    # return Wbrs::Cluster.where(regex: regex) if regex.present?
    cluster_ids = cluster_ids_for_filter
    conditions[:cluster_ids] = cluster_ids if cluster_ids.any?

    Wbrs::Cluster.where(conditions)
  end

  def cluster_ids_for_filter
    # we can save lots of time and provide better UX
    # if we will request only for specific clusters
    # instead of all. that's why we need filter and user params
    # in the data fetcher class
    case filter[:f]
    when 'my'
      ClusterAssignment.get_assigned_cluster_ids_for(user)
    when 'pending'
      ClusterCategorization.get_categorized_cluster_ids_for(user)
    else
      []
    end
  end

  def parse_response(clusters_response)
    clusters = clusters_response['data']

    pending_clusters = fetch_pending_clusters(clusters)

    parsed_clusters = []
    clusters.each_with_index do |cluster, _index|
      parsed_cluster = parse_cluster(cluster)
      parsed_cluster[:is_pending] = cluster_pending?(cluster, pending_clusters)
      parsed_cluster[:categories] = cluster_categories(cluster, pending_clusters)
      parsed_cluster[:platform] = DATA_PATFORM
      parsed_clusters << parsed_cluster
    end

    parsed_clusters
  end

  def cluster_assigned_to_user?(user_clusters, cluster)
    user_clusters.find { |user_cluster| user_cluster.cluster_id == cluster['cluster_id'].to_i }
  end

  def cluster_unassigned?(assigned_cluster_ids, cluster)
    !assigned_cluster_ids.include?(cluster['cluster_id'].to_i)
  end

  def cluster_pending?(cluster, pending_clusters)
    pending_clusters.find { |pending_cluster| pending_cluster.cluster_id == cluster['cluster_id'].to_i }.present?
  end

  def cluster_categories(cluster, pending_clusters)
    pending_cluster = pending_clusters.find { |pending_cluster| pending_cluster.cluster_id == cluster['cluster_id'].to_i }
    return JSON.parse(pending_cluster.category_ids) if pending_cluster

    []
  end

  def parse_cluster(cluster)
    {
      cluster_id: cluster['cluster_id'],
      domain: cluster['domain'],
      global_volume: cluster['glob_volume'],
      cluster_size: cluster['cluster_size'] || ''
    }
  end

  def fetch_pending_clusters(clusters)
    cluster_ids = clusters.map { |cluster| cluster['cluster_id'].to_i }
    ClusterCategorization.where(cluster_id: cluster_ids)
  end
end
