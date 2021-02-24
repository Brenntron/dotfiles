class Wbrs::WsaStatus < Wbrs::Base
  # Checks WSA status for given serial numbers or company names
  # @return JSON response received from WBRS Rule API
  class << self
    def check_statuses(serials, companies)
      response = call_json_request(:post, '/v1/wsa/status', body: url_params(serials, companies))
      JSON.parse(response.body)
    end

    private

    def url_params(serials, companies)
      if serials&.any? && companies&.any?
        raise 'WSA status can not be reached for serials AND companies. Only one parameter should be sent'
      end

      return { serials: serials } unless serials.blank?

      return { companies: companies } unless companies.blank?

      {}
    end
  end
end
