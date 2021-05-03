class Clusters::Wbnp::DataFetcher
  attr_accessor :regex

  include ActionView::Helpers::DateHelper

  DATA_PATFORM = 'WSA'.freeze

  def initialize(regex)
    @regex = regex
  end

  def fetch
    parse_response(fetch_data)
  end

  private

  def fetch_data
    # TODO: add template method for 'fetch' method
    return Wbrs::Cluster.where(regex: regex) if regex.present?

    Wbrs::Cluster.all
  end

  def parse_response(clusters_response)
    clusters = clusters_response['data']

    # TODO: [parsed_cluster[:wbrs_score]] this part is currently removed due to generalizing clusters data
    # wbrs_score = get_wbrs_scores(clusters)
    assignments = fetch_cluster_assignments(clusters)
    top_urls = fetch_top_urls(clusters)
    pending_clusters = fetch_pending_clusters(clusters)

    parsed_clusters = []
    clusters.each_with_index do |cluster, _index|
      parsed_cluster = parse_cluster(cluster)
      # TODO: [parsed_cluster[:wbrs_score]] this part is currently removed due to generalizing clusters data
      # if wbrs_score[index]['response'].present? && wbrs_score[index]['response']['thrt'].present?
      #   parsed_cluster[:wbrs_score] = wbrs_score[index]['response']['thrt']['scor']
      # end
      parsed_cluster[:assigned_to] = cluster_assignee(cluster, assignments)
      parsed_cluster[:is_important] = cluster_important?(cluster, top_urls)
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

  # TODO: [parsed_cluster[:wbrs_score]] this part is currently removed due to generalizing clusters data
  # def get_wbrs_scores(clusters)
  #   beaker_urls_list = []
  #   clusters.each do |cluster|
  #     beaker_urls_list << { 'url' => cluster['domain'] }
  #   end
  #
  #   Beaker::Verdicts.verdicts(beaker_urls_list)
  # end

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
    cluster_assignment = assignments.filter { |assignment| assignment.cluster_id == cluster['cluster_id'].to_i }
    cluster_assignment.first&.user&.cvs_username || ''
  end

  def cluster_important?(cluster, top_urls)
    top_url_clusters = top_urls.filter { |top_url| top_url.url == cluster['domain'] }
    top_url_clusters.first&.is_important
  end
end
