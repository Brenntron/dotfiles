require 'service-tts_services_pb'

class EnrichmentService::Tts < EnrichmentService::EnrichmentServiceBase
  # Request a mapping of taxonomy ID to taxonomy. The available taxonomies
  # include mappings of ID to description, etc., for data sources, threat
  # categories, threat types, etc.
  def self.query_taxonomy_map
    taxonomy_map_request = Talos::TTS::TaxonomyMapRequest.new(app_info: get_app_info)
    remote_stub.query_taxonomy_map(taxonomy_map_request)
  end

  def self.remote_stub
    @remote_stub ||= Talos::Service::TTS::Stub.new(hostport, creds)
  end

end