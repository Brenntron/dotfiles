##################################################################
# example shas
# efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928

class Threatgrid::Search
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.threatgrid
  set_default_request_type :query_string
  set_default_headers ({})

  def self.query_from_data(api_response)

    threat_score = api_response&.dig('data','items')[0]&.dig('item','analysis','threat_score')
    threatgrid_private = api_response&.dig('data','items')[0]&.dig('item','private')

    {threatgrid_score: threat_score, threatgrid_private: threatgrid_private, threatgrid_threshold: 95.0}
  end

  def self.data(sha256_hash)
    call_request_parsed(:get, '/api/v2/search/submissions',
                        input: {q: sha256_hash, sort_by: 'timestamp',
                                api_key: "#{Rails.configuration.threatgrid.api_key}"})
  end

  def self.query(sha256_hash)
    api_response = data(sha256_hash)
    query_from_data(api_response)
  end
end
