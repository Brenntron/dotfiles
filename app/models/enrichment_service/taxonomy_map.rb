class EnrichmentService::TaxonomyMap
  def self.version
    Rails.cache.read("taxonomy_map_version") || 0
  end

  def self.load_map
    map = Rails.cache.read("taxonomy_map") || "{}"
    map = cache_map if JSON.parse(map).blank?
    map
  end

  def self.cache_map
    taxonomy_map = EnrichmentService::Tts.query_taxonomy_map
    taxonomy_map_json = taxonomy_map.to_h.to_json
    Rails.cache.write("taxonomy_map_version", taxonomy_map.version)
    Rails.cache.write("taxonomy_map", taxonomy_map_json)
    taxonomy_map_json
  end

  def self.get_taxonomy(id, entry_id = nil)
    taxonomy_map = JSON.parse(load_map)
    raise EnrichmentService::EnrichmentServiceError, "Missing Taxonomy Map" if taxonomy_map.blank?
    taxonomy_map["taxonomies"].each do |taxonomy|
      if id.to_i == taxonomy["taxonomy_id"].to_i
        if entry_id.present?
          taxonomy["entries"].each do |entry|
            if entry_id.to_i == entry["entry_id"].to_i
              return entry
            end
          end
        else
          return taxonomy
        end
      end
    end
    {"error" => "Could not find taxonomy with id: #{id}#{entry_id.present? ? ", entry_id: #{entry_id}" : ""}"}
  end

  def self.check_version(new_version)
    if new_version > version
      cache_map
    end
  end

end