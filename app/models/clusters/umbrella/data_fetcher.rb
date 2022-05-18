class Clusters::Umbrella::DataFetcher < Clusters::Templates::DataFetcher
  attr_accessor :regex, :filter, :user

  # this is not actual data limit. this limit is to speed the data fetching part up
  # since Clusters Management page has a data limit - this makes no sense to select
  # and parse all Umbrella records.
  # Clusters::ClustersFetcher::CLUSTERS_PAGE_LIMIT can be a source for DATA_LIMIT value
  DATA_LIMIT = 1000
  # UmbrellaCluster has a relation to Platform which should be set to Umbrella
  # But platforms are managed by Talos Intelligence app and can be edited there
  # Since clusters processing are using platform name as an identifier
  # we use hardcoded value to be isolated from potential category name change on TI side
  DATA_PLATFORM = 'Umbrella'.freeze

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
               UmbrellaCluster.visible.where('domain REGEXP ?', regex)
             else
               UmbrellaCluster.visible
             end

      case filter[:f]
      when 'my'
        data = data.where(domain: assigned_domains)
      when 'pending'
        data = data.pending
      end

      case filter[:cluster_type]
      when 'domain'
        data = data.where('domain NOT REGEXP ?', IP_REGEX)
      when 'ip'
        data = data.where('domain REGEXP ?', IP_REGEX)
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
          cluster_size: nil, # no data for Umbrella. follow general data structure
          domain: cluster.domain,
          global_volume: 0, # TODO: remove this tmp placeholder, needed for generic sorting in Clusters::Fetcher.fetch
          is_pending: cluster.pending?,
          categories: cluster.category_ids.present? ? JSON.parse(cluster.category_ids) : [], # mysql can't store arrays =(
          platform: DATA_PLATFORM
        }
      end
    end
end
