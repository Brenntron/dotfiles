class Clusters::Meraki::DataFetcher < Clusters::Templates::DataFetcher
  attr_accessor :regex, :filter, :user

  # this is not actual data limit. this limit is to speed the data fetching part up
  # since Clusters Management page has a data limit - this makes no sense to select
  # and parse all Meraki records.
  # Clusters::ClustersFetcher::CLUSTERS_PAGE_LIMIT can be a source for DATA_LIMIT value
  DATA_LIMIT = 1000
  # MerakiCluster has a relation to Platform which should be set to Meraki
  # But platforms are managed by Talos Intelligence app and can be edited there
  # Since clusters processing are using platform name as an identifier
  # we use hardcoded value to be isolated from potential category name change on TI side
  DATA_PLATFORM = 'Meraki'.freeze

  def initialize(regex, filter = {}, user)
    @regex = regex
    @filter = filter
    @user = user
  end

  def fetch
    parse_response(fetch_data)
  end

  private

  def fetch_data
    data = MerakiCluster.visible.order(traffic_hits: :desc)

    case filter[:f]
    when 'my'
      data = data.where(domain: assigned_domains)
    when 'pending'
      data = data.pending
    end

    data = data.where('domain REGEXP ?', regex) if regex.present?

    case filter[:cluster_type]
    when 'domain'
      data = data.where('!IS_IPV4(domain)')
    when 'ip'
      data = data.where('IS_IPV4(domain)')
    else
      data
    end

    data.first(DATA_LIMIT)
  end

  def assigned_domains
    ClusterAssignment.get_assigned_cluster_domains_for(user)
  end

  def parse_response(clusters)
    clusters.map do |cluster|
      {
          cluster_id: '', # cluster_id is not related to our local record id
          cluster_size: nil, # no data for Meraki. follow general data structure
          domain: cluster.domain,
          global_volume: cluster.traffic_hits,
          is_pending: cluster.pending?,
          categories: cluster.category_ids.present? ? JSON.parse(cluster.category_ids) : [], # mysql can't store arrays =(
          platform: DATA_PLATFORM
      }
    end
  end
end
