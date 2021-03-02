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
    case filter
    when 'my'
      filter_assigned_to_user(clusters)
    when 'unassigned'
      filter_unassigned(clusters)
    else
      clusters
    end
  end

  def filter_assigned_to_user(data)
    user_clusters = ClusterAssignment.fetch_assignments_for(user: user)
    data['data'].filter! do |cluster|
      user_clusters.find { |user_cluster| user_cluster.cluster_id == cluster['cluster_id'].to_i }
    end
    data
  end

  def filter_unassigned(data)
    assigned_cluster_ids = ClusterAssignment.fetch_all_assignments.pluck(:cluster_id)
    data['data'].filter! do |cluster|
      !assigned_cluster_ids.include?(cluster['cluster_id'].to_i)
    end
    data
  end

  def parse_api_response(clusters_response)
    meta = clusters_response['meta']
    clusters = clusters_response['data']

    wbrs_score = get_wbrs_scores(clusters)
    assignments = fetch_cluster_assignments(clusters)

    parsed_clusters = []
    clusters.each_with_index do |cluster, index|
      parsed_cluster = parse_cluster(cluster)
      if wbrs_score[index]['response'].present? && wbrs_score[index]['response']['thrt'].present?
        parsed_cluster[:wbrs_score] = wbrs_score[index]['response']['thrt']['scor']
      end
      parsed_cluster[:assigned_to] = cluster_assignee(cluster, assignments)
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

  def cluster_assignee(cluster, assignments)
    cluster_assignment = assignments.filter { |assignment| assignment.cluster_id == cluster['cluster_id'] }
    cluster_assignment.first&.user&.cvs_username || ''
  end
end
