class Wbrs::RuleHit < Wbrs::Base
  FIELD_NAMES = %w{desc_long description mnemonic probability is_active rule_hit}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :rule_hit)

  SERVICE_STATUS_NAME = "RULEAPI:RULEHIT"

  def self.service_status
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

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(reload: false)
    service_status_data = {}
    unless @all || reload
      response = call_json_request(:get, '/v1/rulehits/info', body: '')

      if response.code >= 300
        (0..2).each do
          response = call_json_request(:get, '/v1/rulehits/info', body: '')
          if response.code < 300
            break
          end
        end
      end

      if response.code >= 300
        service_status_data[:type] = "outage"
        service_status_data[:exception] = "/v1/rulehits/info not loading or responding"
        service_status_data[:exception_details] = response.error rescue response.body

        service_status.log(service_status_data)
      else
        service_status_data[:type] = "working"
        service_status.log(service_status_data)
      end

      response_body = JSON.parse(response.body)
      @all = response_body['data'].map {|datum| new_from_datum(datum)}
    end
    @all
  end

end
