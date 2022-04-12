# basic class to demonstrate usage
class CloudIntel::SenderDomainReputation
  def self.envelope_request(ip_address, mail_from, rcpt_to = [])
    raise "rcpt_to needs to be an array" unless rcpt_to.kind_of?(Array)

    response = Beaker::Sdr.envelope_query(ip_address, smtp_envelope_params: {spf_results: {}, mail_from: mail_from, rcpt_to: rcpt_to})

    response_hash = response.to_h

    CloudIntel::ThreatLevelMap.check_version(response_hash[:threat_level_map_version])
    CloudIntel::ThreatCatMap.check_version(response_hash[:threat_cat_map_version])

    response_hash[:threat_level_mnemonic] = CloudIntel::ThreatLevelMap.get_threat_level_mnemonic(response_hash[:threat_level_id])
    response_hash[:threat_cat] = CloudIntel::ThreatCatMap.lookup(response_hash[:threat_cat_id])

    response_hash
  end

  def self.data_request(ip_address, mail_from, rcpt_to = [])
    raise "rcpt_to needs to be an array" unless rcpt_to.kind_of?(Array)

    response = Beaker::Sdr.data_query(ip_address, smtp_envelope_params: {spf_results: {}, mail_from: mail_from, rcpt_to: rcpt_to})

    response_hash = response.to_h

    CloudIntel::ThreatLevelMap.check_version(response_hash[:threat_level_map_version])
    CloudIntel::ThreatCatMap.check_version(response_hash[:threat_cat_map_version])

    response_hash[:threat_level_mnemonic] = CloudIntel::ThreatLevelMap.get_threat_level_mnemonic(response_hash[:threat_level_id])
    response_hash[:threat_cat] = CloudIntel::ThreatCatMap.lookup(response_hash[:threat_cat_id])

    response_hash
  end
end