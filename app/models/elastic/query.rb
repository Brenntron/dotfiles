class Elastic::Query
  def self.data(sha256_hash)
    client = Elasticsearch::Client.new url: 'https://'+ENV['SERVICE_USER'] + ':' + ENV['SERVICE_PASS'] + '@' + Rails.configuration.elastic.host,
                                       transport_options: { ssl: { ca_file: Rails.configuration.cert_file } }
    client.search q: "SHA256:#{sha256_hash}"
  end

  def self.query(sha256_hash)
    in_zoo = false
    # no need to hit Elasticsearch unless the value looks right
    if sha256_hash.strip.length == 64
      api_response = data(sha256_hash)
      if api_response&.dig("hits","total") and api_response["hits"]["total"] > 0
        in_zoo = true
      end
    end
    in_zoo
  end
end
