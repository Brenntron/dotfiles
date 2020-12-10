class Wbrs::WsaStatus < Wbrs::Base
  # Checks WSA status for given serial numbers
  # @return JSON response received from WBRS Rule API
  def self.check_statuses(serials = [])
    url_params = { serials: serials }
    response = call_json_request(:post, '/v1/wsa/status', body: url_params)
    JSON.parse(response.body)
  end
end
