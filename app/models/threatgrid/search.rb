##################################################################
# example shas
# efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928

class Threatgrid::Search
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.threatgrid
  set_default_request_type :query_string
  set_default_headers ({})

  TEST_HASH = "efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928"

  def self.query_from_data(api_response)

    threat_score = api_response&.dig('data','items')[0]&.dig('item','analysis','threat_score')
    threatgrid_private = api_response&.dig('data','items')[0]&.dig('item','private')

    {threatgrid_score: threat_score, threatgrid_private: threatgrid_private, threatgrid_threshold: 90.0}
  end

  def self.data(sha256_hash)
    call_request_parsed(:get, '/api/v2/search/submissions',
                        input: {q: sha256_hash, sort_by: 'timestamp',
                                api_key: "#{Rails.configuration.threatgrid.api_key}"})
  end

  def self.query(sha256_hash)

    response = {}

    attempts = 0

    while attempts < 5 do
      begin
        api_response = data(sha256_hash)
        response = query_from_data(api_response)
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

    #api_response = data(sha256_hash)
    #query_from_data(api_response)
  end

  def self.health_check
    health_report = {}

    times_to_try = 3
    times_tried = 0
    times_successful = 0
    times_failed = 0
    is_healthy = false

    (1..times_to_try).each do |i|
      begin
        result = data(TEST_HASH)
        if result["id"].present?
          times_successful += 1
        else
          times_failed += 1
        end
        times_tried += 1
      rescue
        times_failed += 1
        times_tried += 1
      end

    end

    if times_successful > times_failed
      is_healthy = true
    end

    health_report[:times_tried] = times_tried
    health_report[:times_successful] = times_successful
    health_report[:times_failed] = times_failed
    health_report[:is_healthy] = is_healthy

    health_report
  end
end
