class Clusters::Filter
  attr_accessor :clusters, :filter_hash, :user

  #IPv4_PATTERN       = /^([0-9]{1,3}\.){3}[0-9]{1,3}/
  #IPv6_PATTERN       = /^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/g

  def initialize(clusters, filter, user)
    @clusters = clusters.dup
    @filter_hash = filter
    @user = user
  end

  def filter
    # user specific filters - filters, selected by users
    # 'my' and 'pending' filters applied in DataFetcher's for better performance
    case filter_hash[:f]
    when 'all'
      clusters
    when 'pending'
      clusters
    when 'unassigned'
      filter_unassigned
    else
      filter_by_default
    end

    filter_garbage
    clusters
  end

  private

  def filter_garbage
    clusters.filter! do |cluster|
      filter_in = true
      is_ip = false
      #for ipv4
      if cluster[:domain].match(/^([0-9]{1,3}\.){3}[0-9]{1,3}/)
        if cluster[:domain].match(/^(10\.|172\.16\.|192\.168\.|198\.18\.|198\.19\.|169\.254\.|127\.|0\.)/)
          filter_in = false
        else
          filter_in = true
        end
        is_ip = true
      end
      #for ipv6
      if cluster[:domain].match(/^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/)
        filter_in = true
        is_ip = true
      end
      #for domains and urls
      if !Complaint.valid_tld?(cluster[:domain]) && is_ip == false
        filter_in = false
      end
      filter_in
    end

  end

  def filter_unassigned
    clusters.filter! do |cluster|
      cluster_unassigned?(cluster)
    end
  end

  def filter_by_default
    # assigned to user + unassigned
    clusters.filter! do |cluster|
      cluster_unassigned?(cluster) || cluster_assigned_to_user?(cluster)
    end
  end

  def cluster_assigned_to_user?(cluster)
    cluster[:assigned_to] == user.cvs_username
  end

  def cluster_unassigned?(cluster)
    cluster[:assigned_to].blank?
  end
end
