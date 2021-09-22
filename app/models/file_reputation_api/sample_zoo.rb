# example shas
# 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54

class FileReputationApi::SampleZoo
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.elastic
  set_default_request_type :query_string
  set_basic_auth

  def self.sha256_lookup(sha256)

    #commenting cache based lookups for the time being, to rule out possible outdated caching causing
    #auto resolution failures

    #cache_key = "sample_zoo:#{sha256}"
    #if Rails.env.development? or Rails.cache.read(cache_key).blank?
    #  call_request_parsed(:get, "/samples/_search?q=SHA256:#{sha256}")
    #else
    #  Rails.cache.read(cache_key)
    #end

    response = {}

    attempts = 0

    while attempts < 5 do
      begin
        response = call_request_parsed(:get, "/samples/_search?q=SHA256:#{sha256}")
        break
      rescue JSON::ParserError
        Rails.logger.error('SampleZoo returned invalid JSON.')
        response = {error: 'Invalid Hash'}
        attempts += 1
      rescue ApiRequester::ApiRequester::ApiRequesterNotAuthorized
        Rails.logger.error('SampleZoo returned an "Unauthorized" response.')
        response = {error: 'Unauthorized'}
        attempts += 1
      rescue
        Rails.logger.error('SampleZoo returned an error response.')
        response = {error: 'Data Currently Unavailable'}
        attempts += 1
      end

    end

    response
  end

  def self.query_from_data(api_response)
    in_zoo = false

    if api_response[:error]
      raise ("#{api_response[:error]}")
    elsif api_response&.dig("hits","total") and api_response["hits"]["total"] > 0
      in_zoo = true
    else
      in_zoo = false
    end

    {in_zoo: in_zoo}
  end
end
