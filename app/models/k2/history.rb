class K2::History < K2::Base
  HISTORY_PATH = "security/insight/k2/1.0".freeze
  DATE_FORMAT = "%Y-%m-%d %H:%M %Z".freeze
  MILISECONDS_IN_SECOND = 1000.freeze

  def self.search(domain)
    http_req = request
    http_req.url = "https://#{host}/#{HISTORY_PATH}"
    domain = domain.is_a?(Array) ? domain : [domain]
    http_req.body = { uris: domain }.to_json
    begin
      response = HTTPI.post(http_req)
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

        item['timelines'].each do |timeline|
          timeline['time'] = Time.at(timeline['time'] / MILISECONDS_IN_SECOND).strftime(DATE_FORMAT)
          result[item['element']] << timeline
        end
      end
    end
  end
end
