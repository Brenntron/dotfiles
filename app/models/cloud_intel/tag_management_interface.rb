class CloudIntel::TagManagementInterface

  def self.read(domain: nil, url: nil, ip: nil, sha: nil)
    result = Tmi::TmiGrpc.read(domain: domain, url: url, ip: ip, sha: sha)
    result_hash = JSON.parse(result.to_h.to_json)

    result_hash['items'].each do |item|
      item['tags'].each do |tag|
        tag['taxonomy'] = EnrichmentService::TaxonomyMap.get_taxonomy(tag['tag']['taxonomy_id'], tag['tag']['taxonomy_entry_id'], true)
      end
    end

    result_hash
  end

end