class Wbrs::RuleUiComplaint < Wbrs::Base
  FIELD_NAMES = %w{prefix_id domain is_active path path_hashed port protocol subdomain truncated category descr mnem }
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :prefix_id)

  SERVICE_STATUS_NAME = "RULEAPI:COMPLAINT_RECORD"

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

  def self.service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def self.new_from_attributes(attributes)
    new(attributes)
  end

  # Get the rules from given criteria.
  # This is not a relation and cannot be chained with other relations.
  # example: get_where(category_ids: [11], active: true)
  # @param [Array<Integer>] complaint_ids: List of ruleui based complaint ids
  # @param [Array<String>] urls: List of URLs
  # @param [Array<String>] statuses: List of complaint statuses
  # @param [Array<String>] add_channels: List of complaint origin channels [wbnp]
  # @param [String] domain_regex: Regex for domain (non empty string)
  # @param [String] subdomain_regex: Regex for domain (non empty string)
  # @param [String] path_regex: Regex for domain (non empty string)
  # @param [Integer] limit: Max number of records to return
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::Prefix>] Array of the results.
  def self.where(conditions = {})
    service_status_data = {}
    params = stringkey_params(conditions)
    # category_ids = Wbrs::Category.category_ids_from_params(params)
    # params['categories'] = category_ids if category_ids.present?
    params['is_active'] = params.delete('active') ? 1 : 0 if params['active'].present?

    response = post_request(path: '/v1/cat/complaints/get', body: params)

    if response.code >= 300
      (0..2).each do
        response = post_request(path: '/v1/cat/complaints/get', body: params)
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/complaints/get not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)

    response_body
    #multicat_results = []

    #response_body['data'].each do |datum|
    #  multicat_results << new_from_attributes(datum.slice(*FIELD_NAMES))
    #end

    #multicat_results
  end



  # Assigns a ticket and some other unnecessary workflow silliness

  # @param [Array<Integer>] complaint_ids: List of complaint ids
  # @param [String] user: username
  def self.assign_tickets(params)
    service_status_data = {}
    response = post_request(path: '/v1/cat/complaints/assign', body: stringkey_params(params))

    if response.code >= 300
      (0..2).each do
        response = post_request(path: '/v1/cat/complaints/assign', body: stringkey_params(params))
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/complaints/assign not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)

    response_body
  end

  def self.tag_complaint(params)
    service_status_data = {}
    response = post_request(path: '/v1/cat/complaints/tag', body: stringkey_params(params))

    if response.code >= 300
      (0..2).each do
        response = post_request(path: '/v1/cat/complaints/tag', body: stringkey_params(params))
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/complaints/tag not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)
    response_body
  end

end
