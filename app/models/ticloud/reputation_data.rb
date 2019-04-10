class Ticloud::ReputationData
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.ticloud
  set_default_request_type :json
  set_default_headers ({})

  def self.query
    api_response = call_request_parsed(:post, '/api/reputation/data/v1/bulk_query/json', request_type: :json, input: {rl: {query: {hash_type: 'sha256'}, hashes:['efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928']}})
  end
end