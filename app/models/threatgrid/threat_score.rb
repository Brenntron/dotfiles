class Threatgrid::ThreatScore
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.threatgrid
  set_default_request_type :query_string
  set_default_headers ({})

  def self.get_threat_score(query)
    api_response = call_request_parsed(:get, '/api/v2/search/submissions', input: {q: query, api_key: "#{Rails.configuration.threatgrid.api_key}"})

    threat_score = api_response&.dig('data','items')[0]&.dig('item','analysis','threat_score')
    threatgrid_private = api_response&.dig('data','items')[0]&.dig('item','private')

    {threat_score: threat_score, threatgrid_private: threatgrid_private}
  end
end