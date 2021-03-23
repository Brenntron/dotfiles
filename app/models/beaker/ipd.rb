require 'service-ipd_services_pb'

class Beaker::Ipd < Beaker::BeakerBase

  def self.remote_stub
    @remote_stub ||= Talos::Service::IPD::Stub.new(hostport, creds)
  end

  def remote_stub
    self.class.remote_stub
  end

  # Request reputation and owner information for an IP address. The first
  # IP address is expected to be the sender IP address. The remaining IP
  # addresses may be IP addresses appearing in email `Received` headers
  # representing hops between mail tranfer agents the message took during
  # delivery (useful for filtering on geolocation information, for
  # example). Batches of 25 IP addresses or less are recommended for
  # optimum query latency.
  # rpc :QueryReputation, ::Talos::IPD::ReputationRequest, ::Talos::IPD::ReputationReply
  def query_reputation(ips)
    endpoints = ips.map { |ip| get_ip_endpoint(ip) }
    reputation_request = Talos::IPD::ReputationRequest.new(app_info: get_app_info, endpoint: endpoints, connection: get_connection)

    remote_stub.query_reputation(reputation_request)
  end

  # Gets mnemonics of multiple IP addresses
  # @param [Array<String>] ips the IP addresses, e.g. ["2.3.4.5", "35.236.52.109"]
  # @return [Hash] keys are inputted IP addresses, values are array of mnemonics
  def reputation_ips(ips)
    reply = query_reputation(ips)
    reply.result.each_with_index.inject({}) do |mnemonic_map, (ip_results, index)|
      mnemonics =
          ip_results.rep_rule_id.map do |rep_rule_id|
            Beaker::ReputationRuleMap.mnemonic(rep_rule_id, version: reply.rule_map_version)
          end
      mnemonic_map[ips[index]] = mnemonics
      mnemonic_map
    end
  end

  # Gets mnemonics of IP address
  # @param [String] ip the IP address, e.g. "2.3.4.5"
  # @return [Array<String>] array of mnemonics for that IP address
  def reputation_ip(ip)
    reply = query_reputation([ip])
    rep_rule_ids = reply.result.map { |ip_result| ip_result.rep_rule_id }.flatten
    rep_rule_ids.map { |rep_rule_id| Beaker::ReputationRuleMap.mnemonic(rep_rule_id, version: reply.rule_map_version) }
  end

  # Request organization information based on domain. See the
  # `DomainInfoRequest` and `DomainInfoReply` messages in `ipd.proto` for
  # details on the structure of the request and response.
  # rpc :QueryDomainInfo, ::Talos::IPD::DomainInfoRequest, ::Talos::IPD::DomainInfoReply
  def query_domain_info(name)
    remote_stub.query_domain_info(Talos::IPD::DomainInfoRequest.new(name: name))
  end
end
