# example shas
# 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54

class FileReputationApi::SampleZoo
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.elastic
  set_default_request_type :json
  set_default_headers ({})

  def self.query_from_data(api_response)
    begin
      if api_response&.dig("hits","total") and api_response["hits"]["total"] > 0
        in_zoo = true
      end
    rescue
      in_zoo = false
    end

    {in_zoo: in_zoo}
  end

  def self.data(sha256_hash)
    client = Elasticsearch::Client.new url: 'https://'+ENV['SERVICE_USER'] + ':' + ENV['SERVICE_PASS'] + '@' + Rails.configuration.elastic.host,
                                       transport_options: { ssl: { ca_file: Rails.configuration.cert_file } }
    client.search q: "SHA256:#{sha256_hash}"
  end

  def self.query(sha256_hash)
    api_response = data(sha256_hash)
    query_from_data(api_response)
  end

end
