class CloudIntel::TagManagementInterface
  TEST_DOMAIN = "google.com"

  def self.read(domain: nil, url: nil, ip: nil, sha: nil)
    result = Tmi::TmiGrpc.read(domain: domain, url: url, ip: ip, sha: sha)
    result_hash = JSON.parse(result.to_h.to_json)

    result_hash['items'].each do |item|
      item['tags'].each do |tag|
        tag_type = EnrichmentService::TaxonomyMap.get_taxonomy(1, tag['tag']['tag_type_id'])
        tag['tag_type'] = tag_type.dig("name", 0, "text")
        if tag['tag']['tag_type_id'] == 1
          taxonomy = EnrichmentService::TaxonomyMap.get_taxonomy(tag['tag']['taxonomy_id'], nil)
          tag['taxonomy'] = {
              "name" => taxonomy['name'],
              "description" => taxonomy['description'],
              "mnemonic" => taxonomy['mnemonic']
          }
          entry = EnrichmentService::TaxonomyMap.get_taxonomy(tag['tag']['taxonomy_id'], tag['tag']['taxonomy_entry_id'])
          tag['taxonomy_entry'] = {
              "entry_id" => entry["entry_id"],
              "name" => entry.dig("name", 0, "text"),
              "description" => entry.dig("description", 0, "text"),
              "mnemonic" => entry["mnemonic"]
          }
        end
      end
    end

    result_hash
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
        result = Tmi::TmiGrpc.read(domain: TEST_DOMAIN)
        if result.items.first.observation.domain == TEST_DOMAIN
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