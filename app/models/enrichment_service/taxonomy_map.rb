class EnrichmentService::TaxonomyMap
  def self.version
    Rails.cache.read("taxonomy_map_version") || 0
  end

  def self.load_map
    map = Rails.cache.read("taxonomy_map") || "{}"
    map = cache_map if JSON.parse(map).blank?
    map
  end

  def self.load_condensed_map
    map = Rails.cache.read("condensed_taxonomy_map") || "{}"
    cache_map if JSON.parse(map).blank?
    Rails.cache.read("condensed_taxonomy_map") || "{}"
  end

  def self.cache_map
    taxonomy_map = EnrichmentService::Tts.query_taxonomy_map
    condense_map(taxonomy_map)
    taxonomy_map_json = taxonomy_map.to_h.to_json
    Rails.cache.write("taxonomy_map_version", taxonomy_map.version)
    Rails.cache.write("taxonomy_map", taxonomy_map_json)
    build_lookups
    taxonomy_map_json
  end

  def self.build_lookups
    taxonomy_map = JSON.parse(load_map)
    taxonomy_map["taxonomies"].each do |taxonomy|
      taxonomy_lookup = taxonomy["entries"].inject({}) { |lookup, entry|
        lookup[entry["entry_id"]] = entry
        lookup
      }

      Rails.cache.write("taxonomy_#{taxonomy["taxonomy_id"]}", taxonomy.to_json)
      Rails.cache.write("taxonomy_lookup_#{taxonomy["taxonomy_id"]}", taxonomy_lookup.to_json)
    end
  end

  def self.get_tag_type(id)
    get_taxonomy(1, id)["name"][0]["text"]
  end

  def self.get_taxonomy(id, entry_id = nil)
    if entry_id.present?
      lookup = JSON.parse(Rails.cache.read("taxonomy_lookup_#{id}") || "{}")
      if lookup.blank?
        build_lookups
        lookup = JSON.parse(Rails.cache.read("taxonomy_lookup_#{id}") || "{}")
      end
      entry = lookup[entry_id.to_s]
      return entry if entry.present?
    else
      taxonomy = JSON.parse(Rails.cache.read("taxonomy_#{id}") || "{}")
      if taxonomy.blank?
        build_lookups
        taxonomy = JSON.parse(Rails.cache.read("taxonomy_#{id}") || "{}")
      end
      return taxonomy if taxonomy.present?
    end
    {"error" => "Could not find taxonomy with id: #{id}#{entry_id.present? ? ", entry_id: #{entry_id}" : ""}"}
  end

  def self.condense_map(map)
    condensed_map = {taxonomies: []}
    map.taxonomies.each_with_index do |tax, i|
      next if i == 0
      taxonomy = {taxonomy_id: tax.taxonomy_id,
                  name: tax.name,
                  description: tax.description,
                  mnemonic: tax.mnemonic,
                  entries: [],
      }

      tax.entries.each do |entry|
        taxonomy[:entries] << {
            entry_id: entry.entry_id,
            name: entry.name[0]&.text,
            short_name: entry.short_name[0]&.text,
            description: entry.description[0]&.text,
            short_description: entry.short_description[0]&.text,
            mnemonic: entry.mnemonic
        }
      end
      condensed_map[:taxonomies] << taxonomy
    end
    Rails.cache.write("condensed_taxonomy_map", condensed_map.to_json)
  end

  def self.check_version(new_version)
    if new_version > version
      cache_map
    end
  end

end