class K2::History < K2::Base
  HISTORY_PATH = "security/insight/k2/1.0".freeze
  DATE_FORMAT = "%Y-%m-%d %H:%M %Z".freeze
  MILISECONDS_IN_SECOND = 1000.freeze
  DAYS_LOOKBACK_PERIOD = 180.freeze

  def self.search(domain)
    http_req = request
    url = URI("https://#{host}/#{HISTORY_PATH}")
    domain = domain.is_a?(Array) ? domain : [domain]
    url.query =  {
      uris: domain.join(','),
      endTime:  Time.now.to_i * MILISECONDS_IN_SECOND, 
      startTime: DAYS_LOOKBACK_PERIOD.days.ago.to_i * MILISECONDS_IN_SECOND
    }.to_query
    http_req.url = url.to_s
    begin
      response = HTTPI.get(http_req)
      request_error_handling(response)
    rescue
      handle_error_response(response)
    end
  end

  def self.parsed_data_for(domain)
    response = search(domain)
    if response.error
      response.to_h
    else
      response.body['queryResults'].each_with_object({}) do |item, result|
        result[item['element']] = []
        is_important = ComplaintEntry.self_importance(item['element']) || false
        item['timelines'].each do |timeline|
          timeline['time'] = Time.at(timeline['time'] / MILISECONDS_IN_SECOND).strftime(DATE_FORMAT)
          timeline['is_important'] = is_important
          result[item['element']] << timeline
        end
      end
    end
  end
end
