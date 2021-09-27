class Clusters::Fetcher
  attr_accessor :filter, :regex, :user

  WSA_DATA_PROVIDER = Clusters::Wbnp::DataFetcher
  NGFW_DATA_PROVIDER = Clusters::Ngfw::DataFetcher

  ALL_DATA_PROVIDERS = [
    WSA_DATA_PROVIDER,
    NGFW_DATA_PROVIDER
  ]

  CLUSTERS_PAGE_LIMIT = 1000

  def initialize(filter, regex, user)
    @filter = filter
    @regex = regex
    @user = user
  end

  def fetch
    clusters_data = fetch_clusters
    clusters_data = populate_3rd_party_clusters_data(clusters_data)
    filtered_clusters = Clusters::Filter.new(clusters_data, filter, user).filter
    filtered_clusters.sort_by { |cluster| cluster[:global_volume] }.reverse.first(CLUSTERS_PAGE_LIMIT)
  end

  private

  def fetch_clusters

    cluster_type = filter ? filter[:cluster_type] : nil

    data_providers_list.map do |provider_class|
      provider_class.new(regex, filter, user).fetch
    end.flatten
  end

  def data_providers_list
    # this is the data filtering that should be a part Clusters::filter
    # but, for page load speedup purposes that will be more efficient to filter by platform
    # before data select
    return ALL_DATA_PROVIDERS if filter.blank?

    case filter[:platform]
    when Clusters::Wbnp::DataFetcher::DATA_PATFORM
      [WSA_DATA_PROVIDER]
    when Clusters::Ngfw::DataFetcher::DATA_PATFORM
      [NGFW_DATA_PROVIDER]
    else
      ALL_DATA_PROVIDERS
    end
  end

  def populate_3rd_party_clusters_data(clusters)
    assignments = fetch_cluster_assignments(clusters)
    wbrs_score = get_wbrs_scores(clusters)
    top_urls = fetch_top_urls(clusters)
    clusters.map do |cluster|
      cluster[:assigned_to] = cluster_assignee(cluster, assignments)
      cluster[:is_important] = cluster_important?(cluster, top_urls)
      cluster[:wbrs_score] = wbrs_score[cluster[:domain]]
      cluster
    end
  end

  def fetch_cluster_assignments(clusters)
    cluster_domains = clusters.map { |cluster| cluster[:domain] }
    ClusterAssignment.fetch_assignments_for(domains: cluster_domains)
  end

  def get_wbrs_scores(clusters)
    beaker_urls_list = []
    clusters.each do |cluster|
      beaker_urls_list << { 'url' => cluster[:domain] }
    end

    parsed_response = {}
    Beaker::Verdicts.verdicts(beaker_urls_list).each do |top_url_response|
      next if top_url_response['response'].blank? || top_url_response['response']['error'].present?

      parsed_response[top_url_response['request']['url']] = top_url_response['response']['thrt']['scor']
    rescue
    end

    parsed_response
  end

  def fetch_top_urls(clusters)
    cluster_domains = clusters.map { |cluster| cluster[:domain] }
    Wbrs::TopUrl.check_urls(cluster_domains)
  end

  def cluster_assignee(cluster, assignments)
    cluster_assignment = assignments.filter { |assignment| assignment.domain == cluster[:domain] }
    cluster_assignment.first&.user&.cvs_username || ''
  end

  def cluster_important?(cluster, top_urls)
    top_url_clusters = top_urls.filter { |top_url| top_url.url == cluster[:domain] }
    top_url_clusters.first&.is_important
  end
end
