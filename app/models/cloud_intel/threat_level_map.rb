class CloudIntel::ThreatLevelMap
  def self.version
    Rails.cache.read("threat_level_map_version") || 0
  end

  def self.load_map
    map = Rails.cache.read("threat_level_map") || "{}"
    map = cache_map if JSON.parse(map).blank?
    map
  end

  def self.cache_map
    begin
      threat_level_map = Beaker::Sdr.query_threat_level_map
    rescue GRPC::Unavailable => e
      return '{}'
    end
    threat_level_map_json = threat_level_map.to_h.to_json
    Rails.cache.write("threat_level_map_version", threat_level_map.version)
    Rails.cache.write("threat_level_map", threat_level_map_json)
    threat_level_map_json
  end

  def self.get_threat_level_mnemonic(id)
    threat_level_map = JSON.parse(load_map)
    return "unknown" if threat_level_map.blank?
    threat_level_map["threat_levels"].each do |threat_level|
      if id.to_i == threat_level["threat_level_id"].to_i
        return threat_level["threat_level_mnemonic"]
      end
    end
    "unknown"
  end

  def self.check_version(new_version)
    if new_version > version
      cache_map
    end
  end

end
