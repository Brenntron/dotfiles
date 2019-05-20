##################################################################
# example shas
# 99e432ac19e5a47d0d1ddfad9f326d5e169ab6651d844d4b800a79f4f78d410f

class FileReputationApi::ReversingLabs
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.reversing_labs
  set_default_request_type :query_string
  set_basic_auth

  def self.sha256_lookup(sha256)
    cache_key = "reversing_labs:#{sha256}"
    if Rails.cache.read(cache_key).blank?
      call_request_parsed(:get, "api/databrowser/rldata/query/sha256/#{sha256}", input: {format: 'json'})
    else
      Rails.cache.read(cache_key)
    end

  rescue JSON::ParserError
    {error: 'Invalid Hash'}
  rescue
    {error: 'Data Currently Unavailable'}
  end

  def self.get_creation_data(sha256)
    api_response = call_request_parsed(:get, "api/databrowser/rldata/query/sha256/#{sha256}", input: {format: 'json'})

    {file_size: api_response['rl']['sample']['sample_size'], sample_type: api_response['rl']['sample']['xref']['sample_type']}

  rescue JSON::ParserError
    {error: 'Invalid Hash'}
  rescue
    {error: 'Data Currently Unavailable'}
  end

  def self.score_of_lookup(api_response)
    reversing_labs_score = 0
    reversing_labs_count = 0
    if api_response&.dig('rl','sample','xref','entries')&.any?
      api_response&.dig('rl','sample','xref','entries')[0]&.dig('scanners').each do |scanner|
        reversing_labs_count += 1
        if !scanner['result'].empty?
          reversing_labs_score += 1
        end
      end
    end

    { reversing_labs_score: reversing_labs_score, reversing_labs_count: reversing_labs_count }
  end

  def self.score(sha256_hash)
    api_response = FileReputationApi::ReversingLabs.sha256_lookup(sha256_hash)
    FileReputationApi::ReversingLabs.score_of_lookup(api_response)
  end

  # Returns an array of certificates
  def self.certificates(sha256)
    api_response = call_request_parsed(:post, '/api/databrowser/rldata/bulk_query/json', request_type: :json, input: {rl: {query: {hash_type: 'sha256', hashes: [sha256] }}}, headers: {'Authorization': 'Basic dS9zb3VyY2VmaXJlOlV1djRsYWl0'})

    if api_response&.dig('rl','entries')&.any? && api_response&.dig('rl','entries')[0]&.dig('analysis','entries').present?
      certificates = api_response&.dig('rl','entries')[0]&.dig('analysis','entries')[0]&.dig('tc_report','metadata','certificate','certificates')
    else
      certificates = nil
    end

    certificates
  end
end
