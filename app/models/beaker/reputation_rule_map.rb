class Beaker::ReputationRuleMap < Beaker::BeakerBase

  private

  def self.remote_stub
    @remote_stub ||= Talos::Service::IPD::Stub.new(hostport, creds)
  end

  def remote_stub
    self.class.remote_stub
  end

  def lookup_version
    @lookup_version ||= Rails.cache.read("reputation_rule_map_version")
  end

  def reputation_rule_lookup
    @reputation_rule_lookup ||= Rails.cache.read("reputation_rule_lookup")
  end

  # Request a mapping of reputation rule IDs to mnemonics. No descriptions
  # are provided, due to confidentiality concerns. This should be called
  # whenever `rule_map_version` in a response from a `QueryReputation`
  # service method call is larger than the version of the Reputation Rule
  # Map that you have cached. For details on the structure of the
  # Reputation Rule Map, see the `ReputationRuleMap` message in
  # `talos.proto`.
  # rpc :QueryRuleMap, ::Talos::IPD::RuleMapRequest, ::Talos::ReputationRuleMap
  def query_rule_map
    rule_map_request = Talos::IPD::RuleMapRequest.new(app_info: get_app_info)
    remote_stub.query_rule_map(rule_map_request)
  end

  def cache_rule_map
    reputation_rule_map = query_rule_map
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
