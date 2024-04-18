class Clusters::Datatable < AjaxDatatablesRails::ActiveRecord
  SUPPORTED_PLATFORMS = ['Umbrella', 'Meraki', 'NGFW'].freeze
  def initialize(params, user)
    @user = user
    @params = params
    @platforms = prepare_platforms_filter(params[:platform])
    super(params, {})
  end

  def view_columns
    @view_columns ||= {
      cluster_id: { source: 'WebCatCluster.id', data: :id },
      domain: { source: 'WebCatCluster.domain', data: :domain, orderable: true },
      global_volume: { source: 'WebCatCluster.traffic_hits', data: :traffic_hits },
      categories: { source: 'WebCatCluster.category_ids', data: :category_ids },
      platform: { source: 'WebCatCluster.cluster_type', data: :cluster_type },
      assigned_to: { source: 'User.cvs_username', data: :cvs_username },
    }
  end

  def data
    format_data(records)
  end

  def get_raw_records
    WebCatCluster.visible
  end

  def sort_records(records)
    case datatable.orders.first.column.sort_query
    when 'users.cvs_username'
      records.sorted_by_user(datatable.orders.first.direction)
    else
      super
    end
  end

  def filter_records(records)
    records = records.where(cluster_type: @platforms) unless @platforms.empty?
    records = records.where('domain REGEXP ?', @params[:regex]) if @params[:regex].present?
    records = records.where('!IS_IPV4(domain)') if @params[:cluster_type] == 'domain'
    records = records.where('IS_IPV4(domain)') if @params[:cluster_type] == 'ip'
    case @params[:f]
    when 'my'
      records = records.where(domain: ClusterAssignment.get_assigned_cluster_domains_for(@user))
    when 'unassigned'
      records = records.left_outer_joins(:cluster_assignments).where(cluster_assignments: { id: nil }).distinct
    when 'pending'
      records = records.pending
    else
      records = records
    end
    records
  end

  private

  def format_data(clusters)
    new_clusters = clusters.dup.to_a
    domains = new_clusters.pluck(:domain)
    dup_clusters = WebCatCluster.where(domain: domains)
    wbrs_scores = wbrs_score(domains)
    is_important = is_important_data(domains)
    assignments = ClusterAssignment.fetch_assignments_for(domains: domains)
    dup_clusters = dup_clusters.map do |cluster|
      {
        cluster_id: cluster['id'],
        is_important: is_important[cluster['domain']],
        domain: cluster['domain'],
        global_volume: cluster['traffic_hits'],
        wbrs_score: wbrs_scores[cluster['domain']],
        platform: cluster['cluster_type'],
        is_pending: cluster['status'] == 'pending' ? true : false,
        assigned_to: assignments.filter { |assignment| assignment['domain'] == cluster['domain'] }.first&.user&.cvs_username || '',
        categories: cluster['category_ids'].nil? ? [] : JSON.parse(cluster['category_ids']),
         }
    end

    data = new_clusters.each_with_object([]) do |cluster, result|
      main_cluster = dup_clusters.select { |cluster_with_data| cluster_with_data[:cluster_id].eql?(cluster['id']) }
      duplicates = dup_clusters.select do |cluster_with_data|
        cluster_with_data[:domain].eql?(cluster.domain) && cluster_with_data[:cluster_id] != cluster['id']
      end
      
      cluster_with_duplicates = main_cluster.first
      cluster_with_duplicates[:duplicates] = duplicates.to_json
      result << cluster_with_duplicates
    end
    data
  end

  def wbrs_score(domains)
    beaker_urls_list = domains.map { |domain| {'url' => domain} }
    parsed_response = {}
    ::Beaker::Verdicts.verdicts(beaker_urls_list).each do |top_url_response|
      next if top_url_response['response'].blank? || top_url_response['response']['error'].present?

      parsed_response[top_url_response['request']['url']] = top_url_response['response']['thrt']['scor']
    rescue
    end

    parsed_response
  end

  def is_important_data(domains)
    wbrs_data = Wbrs::TopUrl.check_urls(domains)

    domains = domains.each_with_object({}) do |domain, result| 
      result[domain] = wbrs_data&.filter { |top_url| top_url.url == domain }&.first&.is_important || false
    end
  end

  private

  def prepare_platforms_filter(platforms)
    platforms = platforms.to_s.split(',')
    return [] if platforms.blank? || platforms.sort == SUPPORTED_PLATFORMS.sort
    
    platforms
  end
end