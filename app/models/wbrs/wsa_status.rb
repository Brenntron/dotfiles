class Wbrs::WsaStatus < Wbrs::Base
  # Checks WSA status for given serial numbers or company names
  # @return JSON response received from WBRS Rule API

  SERVICE_STATUS_NAME = "RULEAPI:WSA_STATUS"

  def self.service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  class << self
    def check_statuses(serials, companies)
      service_status_data = {}
      response = call_json_request(:post, '/v1/wsa/status', body: url_params(serials, companies))

      if response.code >= 300
        (0..2).each do
          response = call_json_request(:post, '/v1/wsa/status', body: url_params(serials, companies))
          if response.code < 300
            break
          end
        end
      end

      if response.code >= 300
        service_status_data[:type] = "outage"
        service_status_data[:exception] = "/v1/wsa/status not loading or responding"
        service_status_data[:exception_details] = response.error rescue response.body

        service_status.log(service_status_data)
      else
        service_status_data[:type] = "working"
        service_status.log(service_status_data)
      end

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
