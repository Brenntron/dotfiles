class CloudIntel::TagManagementInterface

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
              "description" => entry.dig("name", 0, "text"),
              "mnemonic" => entry["mnemonic"]
          }
        end
      end
    end

    result_hash
  end

end