class Clusters::Ngfw::DataFetcher < Clusters::Templates::DataFetcher
  attr_accessor :regex

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

  def initialize(regex)
    @regex = regex
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
    data.order(traffic_hits: :desc).first(DATA_LIMIT)
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
