class FileReputationApi::ReversingLabs
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.reversing_labs
  set_default_request_type :query_string
  set_basic_auth

  # TODO: Either open a ticket to make ApiRequester support HTTP basic auth OR come back here and
  # set up this stuff when it does.

  #       include ApiRequester::ApiRequester

  #       set_api_requester_config Rails.configuration.reversing_labs
  #       set_default_request_type :json
  #       set_default_headers "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}"

  def self.reversing_labs_url
    Rails.configuration.reversing_labs.url
  end

  def self.reversing_labs_username
    Rails.configuration.reversing_labs.username
  end

  def self.reversing_labs_password
    Rails.configuration.reversing_labs.password
  end

  def self.sha256_lookup(sha256)
    cache_key = "reversing_labs:#{sha256}"
    if Rails.cache.read(cache_key).blank?
      response = call_request(:get, "api/databrowser/rldata/query/sha256/#{sha256}", input: {format: 'json'})

        begin
          response = JSON.parse(response.body)
          response
        rescue JSON::ParserError
          {error: 'Invalid Hash'}
        end
      # end
    else
      Rails.cache.read(cache_key)
    end

  rescue JSON::ParserError
    {error: 'Invalid Hash'}
  rescue
    {error: 'Data Currently Unavailable'}
  end

end
