class Clusters::Ngfw::DataFetcher < Clusters::Templates::DataFetcher
  attr_accessor :regex, :filter, :user

  # this is not actual data limit. this limit is to speed the data fetching part up
  # since Clusters Management page has a data limit - this makes no sense to select
  # and parse all NGFW records.
  # Clusters::ClustersFetcher::CLUSTERS_PAGE_LIMIT can be a source for DATA_LIMIT value
  DATA_LIMIT = 1000
  # NgfwCluster has a relation to Platform which should be set to Ngfw
  # But platforms are managed by Talos Intelligence app and can be edited there
  # Since clusters processing are using platform name as an identifier
  # we use hardcoded value to be isolated from potential category name change on TI side
  DATA_PATFORM = 'NGFW'.freeze
  NON_IP_REGEX = '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])){3}$'.freeze

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
    data = if regex.present?
             # apply regex
             NgfwCluster.visible.where('domain REGEXP ?', regex)
           else
             NgfwCluster.visible
           end

    case filter[:f]
    when 'my'
      data = data.where(domain: assigned_domains)
    when 'pending'
      data = data.pending
    end

    case filter[:cluster_type]
    when 'domain'
      data = data.where('domain REGEXP ?', NON_IP_REGEX)
    when 'ip'
      data = data.where('domain NOT REGEXP ?', NON_IP_REGEX)
    else
      data
    end

    data.order(traffic_hits: :desc).first(DATA_LIMIT)
  end

  def assigned_domains
    ClusterAssignment.get_assigned_cluster_domains_for(user)
  end

  def parse_response(clusters)
    clusters.map do |cluster|
      {
        cluster_id: '', # cluster_id is not related to our local record id
        cluster_size: nil, # no data for NGFW. follow general data structure
        domain: cluster.domain,
        global_volume: cluster.traffic_hits,
        is_pending: cluster.pending?,
        categories: cluster.category_ids.present? ? JSON.parse(cluster.category_ids) : [], # mysql can't store arrays =(
        platform: DATA_PATFORM
      }
    end
  end
end
