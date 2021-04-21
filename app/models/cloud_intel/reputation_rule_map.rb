# Class to manage mapping of reputation ids to their information such as mnemonic.
#
# Singleton pattern with instance method.
# Responsible for caching mapping in memcache and in class instance variable.
# Self populates from source of truth resource.
# Has self knowledge of where to delegate call to source of truth.
class CloudIntel::ReputationRuleMap

  private

  def lookup_version
    @lookup_version ||= Rails.cache.read("reputation_rule_map_version")
  end

  def reputation_rule_lookup
    @reputation_rule_lookup ||= Rails.cache.read("reputation_rule_lookup")
  end

  def load_rule_map
    @reputation_rule_lookup = Rails.cache.read("reputation_rule_lookup")
    @lookup_version = Rails.cache.read("reputation_rule_map_version")
  end

  def cache_rule_map
    reputation_rule_map = Beaker::Ipd.query_rule_map
    reputation_rule_map_json = Talos::ReputationRuleMap.encode_json(reputation_rule_map)
    rule_map_data = reputation_rule_map.to_h
    @lookup_version = rule_map_data[:version]

    @reputation_rule_lookup = rule_map_data[:rules].inject({}) do |lookup, rule|
      lookup[rule[:rep_rule_id]] = rule
      lookup
    end

    Rails.cache.write("reputation_rule_map", reputation_rule_map_json)
    Rails.cache.write("reputation_rule_lookup", @reputation_rule_lookup)
    Rails.cache.write("reputation_rule_map_version", @lookup_version)
  end

  public

  # Get the singleton object for this class
  # @return [Beaker::ReputationRuleMap] the singleton object for this class
  def self.instance
    @instance ||= new
  end

  # Map a reputation rule id to its mnemonic
  # Call as `Beaker::ReputationRuleMap.instance.mnemonic(...)`
  # @param [Integer] reputation_rule_id the id to find the mnemonic for.
  # @param [Integer] version the version number that the id belongs to.
  # @return [String] the mnemonic for the reputation rule.
  def mnemonic(reputation_rule_id, version:)
    if reputation_rule_lookup.nil? || lookup_version < version
      load_rule_map
    end
    if reputation_rule_lookup.nil? || lookup_version < version
      cache_rule_map
    end

    @reputation_rule_lookup[reputation_rule_id][:rule_mnemonic]
  end

  # Map a reputation rule id to its mnemonic
  # @param [Integer] reputation_rule_id the id to find the mnemonic for.
  # @param [Integer] version the version number that the id belongs to.
  # @return [String] the mnemonic for the reputation rule.
  def self.mnemonic(reputation_rule_id, version:)
    instance.mnemonic(reputation_rule_id, version: version)
  end
end
