class EnrichmentService::QueryInterface
  def self.interpreted_query(query_item)
    suggestion = get_suggestion(query_item)
    case suggestion
    when 'domain'
      response = EnrichmentService::Enrich.query_domain(query_item)
    when 'ip'
      response = EnrichmentService::Enrich.query_ip(query_item)
    when 'url'
      response = EnrichmentService::Enrich.query_url(query_item)
    when 'sha'
      response = EnrichmentService::Enrich.query_sha(query_item)
    end
    process_response(response)
  end

  def self.domain_query(query_item)
    response = EnrichmentService::Enrich.query_domain(query_item)
    process_response(response)
  end

  def self.ip_query(query_item)
    response = EnrichmentService::Enrich.query_ip(query_item)
    process_response(response)
  end

  def self.url_query(query_item)
    response = EnrichmentService::Enrich.query_url(query_item)
    process_response(response)
  end

  def self.sha_query(query_item)
    response = EnrichmentService::Enrich.query_sha(query_item)
    process_response(response)
  end

  def self.get_suggestion(query_item)
    return 'url' if query_item.match(/https?:\/\//).present?
    return 'sha' if query_item.match(/^[a-fA-F0-9]{64}$/).present?
    ip = IPAddr.new(query_item) rescue nil
    return 'ip' if ip&.ipv4? || ip&.ipv6?
    'domain'
  end

  private

  def self.process_response(response)
    EnrichmentService::TaxonomyMap.check_version(response.taxonomy_map_version)
    response_hash = JSON.parse(response.to_h.to_json)
    response_hash['context_tags'].each do |context_tag|
      extra_params = process_tag(context_tag)
      context_tag['tag_type_name'] = extra_params['tag_type_name']
      context_tag['taxonomy_name'] = extra_params['taxonomy_name']
      context_tag['taxonomy_description'] = extra_params['taxonomy_description']
      context_tag['mapped_taxonomy'] = extra_params['mapped_taxonomy']
    end
    response_hash['web_context_tags'].each do |context_tag|
      extra_params = process_tag(context_tag)
      context_tag['tag_type_name'] = extra_params['tag_type_name']
      context_tag['taxonomy_name'] = extra_params['taxonomy_name']
      context_tag['taxonomy_description'] = extra_params['taxonomy_description']
      context_tag['mapped_taxonomy'] = extra_params['mapped_taxonomy']
    end
    response_hash['email_context_tags'].each do |context_tag|
      extra_params = process_tag(context_tag)
      context_tag['tag_type_name'] = extra_params['tag_type_name']
      context_tag['taxonomy_name'] = extra_params['taxonomy_name']
      context_tag['taxonomy_description'] = extra_params['taxonomy_description']
      context_tag['mapped_taxonomy'] = extra_params['mapped_taxonomy']
    end
    response_hash
  end

  def self.process_tag(context_tag)
    params = {}
    tag_type = EnrichmentService::TaxonomyMap.get_taxonomy(1, context_tag['tag_type_id'])
    if tag_type
      params['tag_type_name'] = tag_type['name'][0]['text']
    end
    taxonomy = EnrichmentService::TaxonomyMap.get_taxonomy(context_tag['taxonomy_id'])
    if taxonomy
      params['taxonomy_name'] = taxonomy['name']
      params['taxonomy_description'] = taxonomy['description']
    end
    params['mapped_taxonomy'] = EnrichmentService::TaxonomyMap.get_taxonomy(context_tag['taxonomy_id'], context_tag['taxonomy_entry_id'])
    params
  end

end