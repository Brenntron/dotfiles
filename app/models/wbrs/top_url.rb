class Wbrs::TopUrl < Wbrs::Base
  FIELD_NAMES = %w{url is_important}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  SERVICE_STATUS_NAME = "RULEAPI:TOP_URL"

  def self.service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end


  def initialize(attributes = {})
    if attributes.keys.present?
      attributes.keys.each do |attr|
        if !FIELD_NAMES.include?(attr)
          self.class.module_eval { attr_accessor attr.to_sym}
        end
      end
    end
    super
  end

  def self.new_from_datum(datum)
    new(datum)
  end

  # Find out if an array of 1 or more urls are in Top URLs
  # @return [Array<Wbrs::TopUrl] Array of the results.
  def self.check_urls(urls = [])
    service_status_data = {}
    url_params = {}
    url_params[:urls] = urls

    response = call_json_request(:post, '/v1/cat/urls/top', body: url_params)

    response_body = JSON.parse(response.body) rescue {}
    @all = response_body.map {|datum, important| new_from_datum({:url => datum, :is_important => important})}

    if @all.blank?
      (0..2).each do
        response = call_json_request(:post, '/v1/cat/urls/top', body: url_params)

        response_body = JSON.parse(response.body) rescue {}
        @all = response_body.map {|datum, important| new_from_datum({:url => datum, :is_important => important})}

        if @all.present?
          break
        end
      end
    end

    if @all.blank?
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/urls/top not loading or responding"
      service_status_data[:exception_details] = response.body rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    @all
  end

end
