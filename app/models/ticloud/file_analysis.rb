class Ticloud::FileAnalysis
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.ticloud
  set_default_request_type :json
  set_default_headers ({})

  # Returns an array of certificates
  def self.certificates(sha256)
    api_response = call_request_parsed(:post, '/api/databrowser/rldata/bulk_query/json', input: {rl: {query: {hash_type: 'sha256', hashes: [sha256] }}}, headers: {'Authorization': 'Basic dS9zb3VyY2VmaXJlOlV1djRsYWl0'})

    if api_response&.dig('rl','entries').any?
      certificates = api_response&.dig('rl','entries')[0]&.dig('analysis','entries')[0]&.dig('tc_report','metadata','certificate','certificates')
    else
      certificates = nil
    end

    certificates
  end
end