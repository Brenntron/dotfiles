require 'service-urs_services_pb'

# Wrapper for Urs class to make gRPC calls.
class Beaker::Urs < Beaker::BeakerBase

  def self.remote_stub
    @remote_stub ||= Talos::Service::URS::Stub.new(hostport, creds)
  end

  def remote_stub
    self.class.remote_stub
  end

  # Request reputation and context for a list of URLs. See the
  # `ReputationRequest` and `ReputationReplyV2` messages in `urs.proto` for
  # the structure of the request and response.
  # rpc :QueryReputationV2, ::Talos::URS::ReputationRequest, ::Talos::URS::ReputationReplyV2
  def self.query_reputation(url, resolved_ip = nil)
    #url = Talos::URL.new(raw_url: url)

    if resolved_ip.present?
      if resolved_ip.kind_of?(String)
        resolved_ip = [get_ip_endpoint(resolved_ip)]
      end
      if resolved_ip.kind_of?(Array)
        resolved_ip = resolved_ip.map {|ip_addr| get_ip_endpoint(ip_addr) }
      end

      url = Talos::URL.new(raw_url: url, endpoint: resolved_ip)
    else
      url = Talos::URL.new(raw_url: url)
    end

    reputation_request = Talos::URS::ReputationRequest.new(app_info: get_app_info,
                                                           connection: get_connection,
                                                           msg_guid: [SecureRandom.uuid.gsub("-", "")].pack("H*"),
                                                           url: [url],
                                                           no_reputation_block_threshold: true)

    remote_stub.query_reputation_v2(reputation_request)
  end

  def self.query_reputation_for_ip(ip)
    #url = Talos::URL.new(raw_url: url)
    if ip.kind_of?(String)
      ip = [get_ip_endpoint(ip)]
    elsif ip.kind_of?(Array)
      ip = ip.map {|ip_addr| get_ip_endpoint(ip_addr) }
    end
    url = Talos::URL.new(raw_url: nil, endpoint: ip)

    reputation_request = Talos::URS::ReputationRequest.new(app_info: get_app_info,
                                                           connection: get_connection,
                                                           msg_guid: [SecureRandom.uuid.gsub("-", "")].pack("H*"),
                                                           url: [url],
                                                           no_reputation_block_threshold: true)

    remote_stub.query_reputation_v2(reputation_request)
  end

  # Request a mapping of threat category ID to mnemonic and description.
  # This should be called whenever `threat_cat_map_version` in a response
  # from a `QueryReputation` or `QueryReputationV2` service method call is
  # larger than the version of the Threat Category Map that you have
  # cached. For details on the structure of the Threat Category Map, see
  # the `ThreatCategoryMap` message in `talos.proto`.
  # rpc :QueryThreatCatMap, ::Talos::URS::ThreatCatMapRequest, ::Talos::ThreatCategoryMap
  def self.query_threat_cat_map
    remote_stub.query_threat_cat_map(Talos::URS::ThreatCatMapRequest.new)
  end

  # Request a mapping of AUP category ID to mnemonic and description.
  # This should be called whenever `aup_cat_map_version` in a response
  # from a `QueryReputation` or `QueryReputationV2` service method call is
  # larger than the version of the AUP Category Map that you have
  # cached. For details on the structure of the AUP Category Map, see
  # the `AUPCategoryMap` message in `talos.proto`.
  # rpc :QueryAUPCatMap, ::Talos::URS::AUPCatMapRequest, ::Talos::AUPCategoryMap
  def self.query_aup_cat_map
    remote_stub.query_aup_cat_map(Talos::URS::AUPCatMapRequest.new)
  end

  # Request a mapping of threat level IDs to names, descriptions, and
  # thresholds. This should be called whenever `threat_level_version` in a
  # response from a `QueryReputation` service method call is larger than
  # the version of the Threat Level Map that you have cached. For details
  # on the structure of the Threat Level Map, see the `ThreatLevelMap`
  # message in `talos.proto`.
  # rpc :QueryThreatLevelMap, ::Talos::URS::ThreatLevelMapRequest, ::Talos::ThreatLevelMap
  def self.query_threat_level_map
    remote_stub.query_threat_level_map(Talos::URS::ThreatLevelMapRequest.new)
  end
end