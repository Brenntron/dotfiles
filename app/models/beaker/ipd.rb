require 'service-ipd_services_pb'

# Wrapper for Beaker/Ipedia Ipd class to make gRPC calls.
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
  def self.query_reputation(ips)
    endpoints = ips.map { |ip| get_ip_endpoint(ip) }
    reputation_request = Talos::IPD::ReputationRequest.new(app_info: get_app_info, endpoint: endpoints, connection: get_connection)

    remote_stub.query_reputation(reputation_request)
  end

  # Request a mapping of reputation rule IDs to mnemonics. No descriptions
  # are provided, due to confidentiality concerns. This should be called
  # whenever `rule_map_version` in a response from a `QueryReputation`
  # service method call is larger than the version of the Reputation Rule
  # Map that you have cached. For details on the structure of the
  # Reputation Rule Map, see the `ReputationRuleMap` message in
  # `talos.proto`.
  # rpc :QueryRuleMap, ::Talos::IPD::RuleMapRequest, ::Talos::ReputationRuleMap
  def self.query_rule_map
    rule_map_request = Talos::IPD::RuleMapRequest.new(app_info: get_app_info)
    remote_stub.query_rule_map(rule_map_request)
  end
end
