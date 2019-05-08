# example shas
# 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54

class FileReputationApi::SampleZoo
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.elastic
  set_default_request_type :query_string
  set_basic_auth

  def self.sha256_lookup(sha256)
    cache_key = "sample_zoo:#{sha256}"
    if Rails.cache.read(cache_key).blank?
      call_request_parsed(:get, "/samples/_search?q=SHA256:#{sha256}")
    else
      Rails.cache.read(cache_key)
    end

  rescue JSON::ParserError
    {error: 'Invalid Hash'}
  rescue
    {error: 'Data Currently Unavailable'}
  end

  def self.query_from_data(api_response)
    in_zoo = false
    begin
      if api_response&.dig("hits","total") and api_response["hits"]["total"] > 0
        in_zoo = true
      end
    rescue
    end

    {in_zoo: in_zoo}
  end

  #def self.flag(sha256_hash)
  #  api_response = FileReputationApi::SampleZoo.sha256_lookup(sha256_hash)
  #  FileReputationApi::SampleZoo.query_from_data(api_response)
  #end
end
