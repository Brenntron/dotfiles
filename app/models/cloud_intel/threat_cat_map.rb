class CloudIntel::ThreatCatMap
  def self.version
    Rails.cache.read("threat_cat_map_version") || 0
  end

  def self.load_map
    map = Rails.cache.read("threat_cat_map") || "{}"
    map = cache_map if JSON.parse(map).blank?
    map
  end

  def self.load_lookup
    lookup = Rails.cache.read("threat_cat_lookup") || "{}"
    if JSON.parse(lookup).blank?
      cache_map
      lookup = Rails.cache.read("threat_cat_lookup") || "{}"
    end
    lookup
  end

  def self.cache_map
    threat_cat_map = Beaker::Sdr.query_threat_cat_map
    threat_cat_map_json = threat_cat_map.to_h.to_json

    threat_cat_lookup = JSON.parse(threat_cat_map_json)["threat_cats"].inject({}) {|lookup, threat_cat|
      lookup[threat_cat["threat_cat_id"]] = threat_cat
      lookup
    }

    Rails.cache.write("threat_cat_map_version", threat_cat_map.version)
    Rails.cache.write("threat_cat_map", threat_cat_map_json)
    Rails.cache.write("threat_cat_lookup", threat_cat_lookup.to_json)

    threat_cat_map_json
  end

  def self.lookup(ids)
    results = []
    return results if ids.blank?
    lookup = JSON.parse(load_lookup)
    ids.each do |id|
      results << lookup[id.to_s]
    end
    results
  end

  def self.check_version(new_version)
    if new_version > version
      cache_map
    end
  end

end
