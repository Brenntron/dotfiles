class Clusters::ClustersFetcher
  attr_accessor :filter, :regex, :user

  DATA_PROVIDERS = [
    Clusters::Wbnp::DataFetcher
  ]

  def initialize(filter, regex, user)
    @filter = filter
    @regex = regex
    @user = user
  end

  def fetch
    clusters_data = fetch_clusters
    filter_clusters(clusters_data)
  end

  private

  def fetch_clusters
    DATA_PROVIDERS.map do |provider_class|
      provider_class.new(regex).fetch
    end.flatten
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
    clusters_domains = data.map { |cluster| cluster[:domain] }
    complaint_entries = ComplaintEntry.where(domain: clusters_domains).or(ComplaintEntry.where(ip_address: clusters_domains))
    data.filter! do |cluster|
      complaint_entries.find do |complaint_entry|
        complaint_entry.domain == cluster[:domain] ||
          complaint_entry.ip_address == cluster[:domain]
      end.nil?
    end
    data
  end

  def filter_assigned_to_user(data)
    data.filter! do |cluster|
      cluster_assigned_to_user?(cluster)
    end
    data
  end

  def filter_unassigned(data)
    data.filter! do |cluster|
      cluster_unassigned?(cluster)
    end
    data
  end

  def filter_pending(data)
    data.filter! do |cluster|
      cluster[:is_pending]
    end
    data
  end

  def filter_by_default(data)
    # assigned to user + unassigned
    data.filter! do |cluster|
      cluster_unassigned?(cluster) || cluster_assigned_to_user?(cluster)
    end
    data
  end

  def cluster_assigned_to_user?(cluster)
    cluster[:assigned_to] == user.cvs_username
  end

  def cluster_unassigned?(cluster)
    cluster[:assigned_to].blank?
  end

  def cluster_pending?(cluster, pending_clusters)
    pending_clusters.find { |pending_cluster| pending_cluster.cluster_id == cluster[:cluster_id].to_i }.present?
  end
end
