class Webcat::ClustersFetcher
  attr_accessor :filter, :regex, :user

  def initialize(filter, regex, user)
    @filter = filter
    @regex = regex
    @user = user
  end

  def fetch
    wbrs_data = fetch_clusters_from_api
    filtered_data = filter_clusters(wbrs_data)
    parse_api_response(filtered_data)
  end

  private

  def fetch_clusters_from_api
    return Wbrs::Cluster.where(regex: regex) if regex.present?

    Wbrs::Cluster.all
  end

  def filter_clusters(clusters)
    # general filters - always applies for all clusters
    clusters = filter_by_categorized(clusters)

    # user specific filters - filters, selected by users
    case filter
    when 'all'
      clusters
    when 'my'
      filter_assigned_to_user(clusters)
    when 'unassigned'
      filter_unassigned(clusters)
    when 'pending'
      filter_pending(clusters)
    else
      filter_by_default(clusters)
    end
  end

  def filter_by_categorized(data)
    # filters out clusters if they have Complaint equivalent
    clusters_domains = data['data'].map { |cluster| cluster['domain'] }
    complaint_entries = ComplaintEntry.where(domain: clusters_domains).or(ComplaintEntry.where(ip_address: clusters_domains))
    data['data'].filter! do |cluster|
      complaint_entries.find do |complaint_entry|
        complaint_entry.domain == cluster['domain'] ||
          complaint_entry.ip_address == cluster['domain']
      end.nil?
    end
    data
  end

  def filter_assigned_to_user(data)
    user_clusters = ClusterAssignment.fetch_assignments_for(user: user)
    data['data'].filter! do |cluster|
      cluster_assigned_to_user?(user_clusters, cluster)
    end
    data
  end

  def filter_unassigned(data)
    assigned_cluster_ids = ClusterAssignment.fetch_all_assignments.pluck(:cluster_id)
    data['data'].filter! do |cluster|
      cluster_unassigned?(assigned_cluster_ids, cluster)
    end
    data
  end

  def filter_pending(data)
    pending_clusters = fetch_pending_clusters(data['data'])
    data['data'].filter! do |cluster|
      cluster_pending?(cluster, pending_clusters)
    end
    data
  end

  def filter_by_default(data)
    # assigned to user + unassigned
    user_clusters = ClusterAssignment.fetch_assignments_for(user: user)
    assigned_cluster_ids = ClusterAssignment.fetch_all_assignments.pluck(:cluster_id)
    data['data'].filter! do |cluster|
      cluster_unassigned?(assigned_cluster_ids, cluster) || cluster_assigned_to_user?(user_clusters, cluster)
    end
    data
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
    pending_cluster = pending_clusters.find { |pending_cluster| pending_cluster.cluster_id == cluster['cluster_id'] }
    return JSON.parse(pending_cluster.category_ids) if pending_cluster
    []
  end

  def parse_api_response(clusters_response)
    meta = clusters_response['meta']
    clusters = clusters_response['data']

    wbrs_score = get_wbrs_scores(clusters)
    assignments = fetch_cluster_assignments(clusters)
    top_urls = fetch_top_urls(clusters)
    pending_clusters = fetch_pending_clusters(clusters)

    parsed_clusters = []
    clusters.each_with_index do |cluster, index|
      parsed_cluster = parse_cluster(cluster)
      if wbrs_score[index]['response'].present? && wbrs_score[index]['response']['thrt'].present?
        parsed_cluster[:wbrs_score] = wbrs_score[index]['response']['thrt']['scor']
      end
      parsed_cluster[:assigned_to] = cluster_assignee(cluster, assignments)
      parsed_cluster[:is_important] = cluster_important?(cluster, top_urls)
      parsed_cluster[:is_pending] = cluster_pending?(cluster, pending_clusters)
      parsed_cluster[:categories] = cluster_categories(cluster, pending_clusters)
      parsed_clusters << parsed_cluster
    end

    {
      meta: meta,
      data: parsed_clusters
    }
  end

  def get_wbrs_scores(clusters)
    beaker_urls_list = []
    clusters.each do |cluster|
      beaker_urls_list << { 'url' => cluster['domain'] }
    end

    Beaker::Verdicts.verdicts(beaker_urls_list)
  end

  def parse_cluster(cluster)
    {
      cluster_id: cluster['cluster_id'],
      domain: cluster['domain'],
      global_volume: cluster['glob_volume'],
      ctime: cluster['ctime'],
      cluster_size: cluster['cluster_size'] || '',
      age: distance_of_time_in_words(Time.now, Time.parse(cluster['ctime']))
    }
  end

  def fetch_cluster_assignments(clusters)
    cluster_ids = clusters.map { |cluster| cluster['cluster_id'].to_i }
    ClusterAssignment.fetch_assignments_for(clusters: cluster_ids)
  end

  def fetch_top_urls(clusters)
    cluster_domains = clusters.map { |cluster| cluster['domain'] }
    Wbrs::TopUrl.check_urls(cluster_domains)
  end

  def fetch_pending_clusters(clusters)
    cluster_ids = clusters.map { |cluster| cluster['cluster_id'].to_i }
    ClusterCategorization.where(cluster_id: cluster_ids)
  end

  def cluster_assignee(cluster, assignments)
    cluster_assignment = assignments.filter { |assignment| assignment.cluster_id == cluster['cluster_id'] }
    cluster_assignment.first&.user&.cvs_username || ''
  end

  def cluster_important?(cluster, top_urls)
    top_url_clusters = top_urls.filter { |top_url| top_url.url == cluster['domain'] }
    top_url_clusters.first&.is_important
  end
end
