class CloudIntel::ReputationHit
  # Gets mnemonics of multiple IP addresses
  #
  # example:
  #   ReputiationHit.mnemonics_ips(["2.3.4.5", "35.236.52.109"])
  #   => { "2.3.4.5" => {mnemonics: ['Pbl']},
  #        "35.236.52.109" => {mnemonics: ['Smd']}}
  #
  # @param [Array<String>] ips the IP addresses, e.g. ["2.3.4.5", "35.236.52.109"]
  # @return [Hash] keys are inputted IP addresses, values are hash with array of mnemonics
  def self.mnemonics_ips(ips)
    reply = Beaker::Ipd.query_reputation(ips)
    version = reply.rule_map_version
    reply.result.each_with_index.inject({}) do |mnemonic_map, (ip_results, index)|
      mnemonics =
          ip_results.rep_rule_id.map do |rep_rule_id|
            CloudIntel::ReputationRuleMap.mnemonic(rep_rule_id, version: version)
          end
      mnemonic_map[ips[index]] = {mnemonics: mnemonics}
      mnemonic_map
    end
  end

  # Gets mnemonics of single IP addresses
  #
  # example:
  #   ReputiationHit.mnemonics_ip("2.3.4.5")
  #   => ['Pbl', 'Smd']
  #
  # @param [String] ip the IP address, e.g. "2.3.4.5"
  # @return [Array<String>] array of mnemonics for that IP address
  def self.mnemonics_ip(ip)
    reply = Beaker::Ipd.query_reputation([ip])
    version = reply.rule_map_version
    rep_rule_ids = reply.result.map { |ip_result| ip_result.rep_rule_id }.flatten
    rep_rule_ids.map { |rep_rule_id| CloudIntel::ReputationRuleMap.mnemonic(rep_rule_id, version: version) }
  end

  # spam_prob_x10000
end
