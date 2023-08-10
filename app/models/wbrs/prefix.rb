class Wbrs::Prefix < Wbrs::Base
  FIELD_NAMES = %w{prefix_id domain is_active path path_hashed port protocol subdomain truncated category
                   descr desc_long mnem category_id}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :prefix_id)

  SERVICE_STATUS_NAME = "RULEAPI:CATEGORY_PREFIX"

  def self.service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def is_active?
    0 < is_active
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

  def self.new_from_attributes(attributes)
    new(attributes)
  end

  # Get the rules from given criteria.
  # This is not a relation and cannot be chained with other relations.
  # example: get_where(category_ids: [11], active: true)
  # @param [Array<Integer>] prefix_ids: List of prefixes ids
  # @param [Array<String>] urls: List of URLs
  # @param [Array<Integer>] category_ids: List of prefixes categories
  # @param [Array<Wbrs::Category>] categories: List of prefixes category objects
  # @param [Boolean] active: prefixes active/disable status
  # @param [Integer] limit: Max number of records to return
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::Prefix>] Array of the results.
  # TODO Almost all the time "where" is called with "urls", so add a convenience method "from_urls"
  def self.where(conditions = {})
    service_status_data = {}
    params = stringkey_params(conditions)
    # category_ids = Wbrs::Category.category_ids_from_params(params)
    # params['categories'] = category_ids if category_ids.present?
    params['is_active'] = params.delete('active') ? 1 : 0 if params['active'].present?

    response = post_request(path: '/v1/cat/rules/get', body: params)

    if response.code >= 300
      (0..2).each do
        response = post_request(path: '/v1/cat/rules/get', body: params)
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/rules/get not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)

    multicat_results = []

    response_body['data'].each do |datum|
      multicat_results << new_from_attributes(datum.slice(*FIELD_NAMES))
    end

    multicat_results
  end

  # @return [Array<Wbrs::Category>] array of categories related to this prefix.
  def categories
    service_status_data = {}
    response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/get', body: { prefix_ids: [ id ] })

    if response.code >= 300
      (0..2).each do
        response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/get', body: { prefix_ids: [ id ] })
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/rules/get not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)

    response_body['data'].map do |datum|
      Wbrs::AssociatedCategory.new(category_id: datum['category_id'],
                                   confidence: datum['confidence'],
                                   is_active: datum['is_active'])
    end
  end

  def category_object
    case
    when @category_object
      # do nothing
    when self.category_id
      @category_object = Wbrs::Category.find(self.category_id)
    else
      @category_object = categories.first
    end
    @category_object
  end

  def category_names
    categories.map {|category| category.descr}
  end

  # @param prefixes Array of these objects
  # @return Array[String] Array of category names
  def self.category_names(prefixes)
    prefixes.inject([]) do |category_names, prefix|
      category_names += prefix.category_names
      category_names
    end.uniq.join(',')
  end

  # Get a prefix by id
  # @param [Integer] id the prefix id
  # @return [Wbrs::Prefix] the prefix
  def self.find(id)
    where(prefix_id: id, limit: 1).first
  end

  # Get the audit history
  # @return [Array<Wbrs::HistoryRecord] the collection of audit history records.
  def history_records
    Wbrs::HistoryRecord.where(prefix_id: id)
  end

  # Creates a new prefix from a given URL and a list of categories.
  # @param [String] url: An URL
  # @param [Array<Integer>] category_ids: List of prefixes categories
  # @param [String] user: The user for this action
  # @param [String] description: A description
  # @return [Integer] id of created prefix.
  def self.create_from_url(params)
    service_status_data = {}
    response = post_request(path: '/v1/cat/rules/add', body: stringkey_params(params))

    if response.code >= 300
      (0..2).each do
        response = post_request(path: '/v1/cat/rules/add', body: stringkey_params(params))
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/rules/add not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)
    response_body['Created']
  end

  # Sets the categories on a prefix to given list of categories.
  # @param [Array<Wbrs::Category | Integer>] category_ids: List of categories or category ids.
  # @param [String] user: The user for this action
  # @param [String] description: A description
  # @return [Integer] id of updated prefix.
  def set_categories(category_ids_array, user:, description: nil, prefix_id: nil)
    service_status_data = {}
    options = {
        'prefix_id' => prefix_id || self.id,
        'categories' => category_ids_array,
        'user' => user,
        'description' => description
    }
    response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/edit', body: Wbrs::Prefix.stringkey_params(options))

    if response.code >= 300
      (0..2).each do
        response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/edit', body: Wbrs::Prefix.stringkey_params(options))
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/rules/edit not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end



    response_body = JSON.parse(response.body)
    response_body['Updated']
  end
  # Disables the rules on this prefix.
  # @param [String] user: The user for this action

  def disable(user:)
    service_status_data = {}

    options = { 'prefix_ids' => [ self.id ], 'user' => user }
    response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/disable', body: Wbrs::Prefix.stringkey_params(options))

    if response.code >= 300
      (0..2).each do
        response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/disable', body: Wbrs::Prefix.stringkey_params(options))
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/rules/disable not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end


    response
  end

  def self.disable(prefix_id, user)
    service_status_data = {}

    options = { 'prefix_ids' => [ prefix_id ], 'user' => user }
    response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/disable', body: Wbrs::Prefix.stringkey_params(options))

    if response.code >= 300
      (0..2).each do
        response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/disable', body: Wbrs::Prefix.stringkey_params(options))
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/rules/disable not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response
  end

  def self.rulelib_rule_sources
    service_status_data = {}
    response = Wbrs::Prefix.call_json_request(:get, "/v1/wbrsrulelib/cat/sources", body: {})

    if response.code >= 300
      (0..2).each do
        response = Wbrs::Prefix.call_json_request(:get, "/v1/wbrsrulelib/cat/sources", body: {})
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/wbrsrulelib/cat/sources not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end


    response_body = JSON.parse(response.body)
    response_body
  end

  def self.get_certainty_sources_for_urls(urls, strict_matching = 1)
    service_status_data = {}
    options = {}
    options[:urls] = urls
    options[:strict_matching] = strict_matching

    response = Wbrs::Prefix.post_request(path: '/v1/wbrsrulelib/cat/rules', body: Wbrs::Prefix.stringkey_params(options))

    if response.code >= 300
      (0..2).each do
        response = Wbrs::Prefix.post_request(path: '/v1/wbrsrulelib/cat/rules', body: Wbrs::Prefix.stringkey_params(options))
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/wbrsrulelib/cat/rules not loading or responding"
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
