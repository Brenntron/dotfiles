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
    api_response = call_request_parsed(:get, '/api/v2/search/submissions', input: {q: sha256_hash, sort_by: 'timestamp', api_key: "#{Rails.configuration.threatgrid.api_key}"})

    submitted_to_tg = api_response
    run_status = api_response
    threat_score = api_response&.dig('data','items')[0]&.dig('item','analysis','threat_score')

    # Tags (can contain many entries)
    tag_data = api_response
    tags = api_response

    control = api_response
    vm_name = api_response
    run_time = api_response
    os = api_response

    # Behaviors (can contain many entries)
    behavior_data = api_response
    behaviors = api_response

    full_json = api_response.to_json



    {submitted_to_tg: submitted_to_tg, run_status: run_status, threat_score: threat_score, tags: tags, control: control,
     vm_name: vm_name, run_time: run_time, os: os, behaviors: behaviors, full_json: full_json}
  end
end
