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

end
