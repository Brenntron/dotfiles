##################################################################
# example shas
# efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928

class Threatgrid::Search
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.threatgrid
  set_default_request_type :query_string
  set_default_headers ({})

  def self.query(query_text)
    api_response = call_request_parsed(:get, '/api/v2/search/submissions', input: {q: query_text, sort_by: 'timestamp', api_key: "#{Rails.configuration.threatgrid.api_key}"})

    threat_score = api_response&.dig('data','items')[0]&.dig('item','analysis','threat_score')
    threatgrid_private = api_response&.dig('data','items')[0]&.dig('item','private')

    {threat_score: threat_score, threatgrid_private: threatgrid_private}
  end

  def self.data(sha256_hash)
    call_request_parsed(:get, '/api/v2/search/submissions', input: {q: sha256_hash, sort_by: 'timestamp', api_key: "#{Rails.configuration.threatgrid.api_key}"})
  end
end
