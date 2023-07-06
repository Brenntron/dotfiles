class CloudIntel::TagManagementInterface

  def self.read(domain: nil, url: nil, ip: nil, sha: nil)
    result = Tmi::TmiGrpc.read(domain: domain, url: url, ip: ip, sha: sha)
    result_hash = JSON.parse(result.to_h.to_json)

    result_hash['items'].each do |item|
      item['tags'].each do |tag|
        tag['tag_type'] = EnrichmentService::TaxonomyMap.get_tag_type(tag['tag']['tag_type_id'])
        if tag['tag']['tag_type_id'] == 1
          taxonomy = EnrichmentService::TaxonomyMap.get_taxonomy(tag['tag']['taxonomy_id'], nil, true)
          tag['taxonomy'] = {
              "name" => taxonomy['name'],
              "description" => taxonomy['description'],
              "mnemonic" => taxonomy['mnemonic']
          }
          tag['taxonomy_entry'] = EnrichmentService::TaxonomyMap.get_taxonomy(tag['tag']['taxonomy_id'], tag['tag']['taxonomy_entry_id'], true)
        end
      end
    end

    result_hash
  end

end