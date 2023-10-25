class EnrichmentService::QueryInterface

  TEST_URL = "www.google.com"

  def self.interpreted_query(query_item)
    suggestion = get_suggestion(query_item)
    prevalence_response = nil
    case suggestion
    when 'domain'
      response = ::EnrichmentService::Enrich.query_domain(query_item)
      prevalence_response = ::EnrichmentService::Enrich.query_domain_prevalence([query_item])
    when 'ip'
      response = ::EnrichmentService::Enrich.query_ip(query_item)
      prevalence_response = ::EnrichmentService::Enrich.query_ip_prevalence([query_item])
    when 'url'
      response = ::EnrichmentService::Enrich.query_url(query_item)
      prevalence_response = ::EnrichmentService::Enrich.query_domain_prevalence([DisputeEntry.safe_domain_of(query_item)])
    when 'sha'
      response = ::EnrichmentService::Enrich.query_sha(query_item)
      prevalence_response = ::EnrichmentService::Enrich.query_hash_prevalence([query_item])
    end
    process_response(response, prevalence_response)
  end

  def self.domain_query(query_item)
    response = ::EnrichmentService::Enrich.query_domain(query_item)
    prevalence_response = ::EnrichmentService::Enrich.query_domain_prevalence([query_item])
    process_response(response, prevalence_response)
  end

  def self.ip_query(query_item)
    response = ::EnrichmentService::Enrich.query_ip(query_item)
    prevalence_response = ::EnrichmentSerivce::Enrich.query_ip_prevalence([query_item])
    process_response(response, prevalence_response)
  end

  def self.url_query(query_item)
    response = ::EnrichmentService::Enrich.query_url(query_item)
    prevalence_response = ::EnrichmentService::Enrich.query_domain_prevalence([DisputeEntry.safe_domain_of(query_item)])
    process_response(response, prevalence_response)
  end

  def self.sha_query(query_item)
    response = ::EnrichmentService::Enrich.query_sha(query_item)
    prevalence_response = ::EnrichmentService::Enrich.query_hash_prevalence([query_item])
    process_response(response, prevalence_response)
  end

  def self.get_suggestion(query_item)
    return 'sha' if query_item.match(/^[a-fA-F0-9]{64}$/).present?
    ip = IPAddr.new(query_item) rescue nil
    return 'ip' if ip&.ipv4? || ip&.ipv6?

    parser = Addressable::URI
    uri = parser.parse(parser.parse(query_item).scheme.nil? ? "http://#{query_item}" : query_item)
    return 'domain' if uri.hostname == query_item

    'url'
  end

  private

  def self.process_response(response, prevalence = nil)
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
    if prevalence.present?
      prevalence_hash = JSON.parse(prevalence.to_h.to_json)
      response_hash['prevalence'] = prevalence_hash
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

  def self.health_check
    health_report = {}

    times_to_try = 3
    times_tried = 0
    times_successful = 0
    times_failed = 0
    is_healthy = false

    (1..times_to_try).each do |i|
      begin

        result = interpreted_query(TEST_URL)

        if result["context_tags"].present?
          times_successful += 1
        else
          times_failed += 1
        end
        times_tried += 1
      rescue
        times_failed += 1
        times_tried += 1
      end

    end

    if times_successful > times_failed
      is_healthy = true
    end

    health_report[:times_tried] = times_tried
    health_report[:times_successful] = times_successful
    health_report[:times_failed] = times_failed
    health_report[:is_healthy] = is_healthy

    health_report
  end

end
