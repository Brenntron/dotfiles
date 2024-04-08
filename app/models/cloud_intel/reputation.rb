# A class for an instance of the reputation of one network address.
# Has self knowledge of where to get the reputation from source of truth service.
class CloudIntel::Reputation
  attr_reader :version

  private def initialize(ip_result, version:)
    @ip_result = ip_result
    @version = version
  end

  private def ip_result
    @ip_result
  end

  def score
    ip_result.reputation_x10.to_f / 10.0
  end

  # Key id for reputation hits.
  # Value can be looked up in ReputationRuleMap class.
  # @return [Array<Integer>] ids for reputation hits.
  def rep_rule_ids
    ip_result.rep_rule_id
  end

  # Attribute of mnemonics of reputation hits including blocklist, allowlist and others.
  # @return [Array<String>] collection of mnemonics for reputation hit.
  def mnemonics
    @mnemonics ||= rep_rule_ids.map do |rep_rule_id|
      CloudIntel::ReputationRuleMap.mnemonic(rep_rule_id, version: version)
    end
  end

  # Chance in 10000 that the given network address is malware.
  # @return [Integer] Chance in 10000.
  def spam_prob_x10000
    ip_result.spam_prob_x10000
  end

  # Percent chance that the given network address is malware.
  # @return [Integer] Percent chance.
  def spam_percent
    spam_prob_x10000 / 100.0
  end

  # Gets mnemonics of multiple IP addresses
  #
  # example:
  #   Reputation.reputation_ips(["2.3.4.5", "35.236.52.109"])
  #   => { "2.3.4.5" => {reputation: Reputation},
  #        "35.236.52.109" => {reputation: Reputation}
  #
  # @param [Array<String>] ips the IP addresses, e.g. ["2.3.4.5", "35.236.52.109"]
  # @return [Hash] keys are inputted IP addresses, values are hash with ReputationHit
  def self.reputation_ips(ips)
    reply = Beaker::Ipd.query_reputation(ips)
    version = reply.rule_map_version
    reply.result.each_with_index.inject({}) do |mnemonic_map, (ip_results, index)|
      mnemonic_map[ips[index]] = {reputation: new(ip_results, version: version)}
      mnemonic_map
    end
  end

  # Gets mnemonics of multiple IP addresses
  #
  # example:
  #   Reputation.mnemonics_ips(["2.3.4.5", "35.236.52.109"])
  #   => { "2.3.4.5" => {mnemonics: ['Pbl']},
  #        "35.236.52.109" => {mnemonics: ['Smd']}}
  #
  # @param [Array<String>] ips the IP addresses, e.g. ["2.3.4.5", "35.236.52.109"]
  # @return [Hash] keys are inputted IP addresses, values are hash with array of mnemonics
  def self.mnemonics_ips(ips)
    reputations = reputation_ips(ips)
    ips.each do |ip|
      reputations[ip][:mnemonics] = reputations[ip][:reputation].mnemonics
    end
    reputations
  end

  # Gets mnemonics of single IP addresses
  #
  # example:
  #   Reputation.mnemonics_ip("2.3.4.5")
  #   => ['Pbl', 'Smd']
  #
  # @param [String] ip the IP address, e.g. "2.3.4.5"
  # @return [Array<String>] array of mnemonics for that IP address
  def self.mnemonics_ip(ip)
    reputations = reputation_ips([ip])
    reputations[ip][:reputation].mnemonics
  end
end
