class Wbrs::Prefix < Wbrs::Base
  FIELD_NAMES = %w{prefix_id domain is_active path path_hashed port protocol subdomain truncated}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS
  class << self
    attr_reader :all_hash
  end

  alias_method(:id, :prefix_id)

  def self.new_from_attributes(attributes)
    new(attributes)
  end

  # Get the rules from given criteria.
  # This is not a relation and cannot be chained with other relations.
  # example: get_where(category_ids = [11], active: true)
  # @param [Array<Integer>] prefix_ids: List of prefixes ids
  # @param [Array<String>] urls: List of URLs
  # @param [Array<Integer>] category_ids: List of prefixes categories
  # @param [Boolean] active: prefixes active/disable status
  # @param [Integer] limit: Max number of records to return
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::Prefix>] Array of the results.
  def self.where(conditions = {})
    params = stringkey_params(conditions)
    params['categories'] = params.delete('category_ids') unless params['category_ids'].nil?
    params['is_active'] = params.delete('active') ? 1 : 0 unless params['active'].nil?
    response = post_request(path: '/v1/cat/rules/get', body: params)

    response_body = JSON.parse(response.body)
    response_body['data'].inject({}) do |prefix_hash, datum|
      prefix_id = datum['prefix_id']
      unless prefix_hash[prefix_id]
        prefix_hash[prefix_id] = new(datum.slice(*FIELD_NAMES))
      end
      prefix_hash
    end.values
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
  def self.create_from_url(options)
    options['categories'] = Wbrs::Category.category_ids(options['categories']) if options['categories'].present?
    response = post_request(path: '/v1/cat/rules/add', body: stringkey_params(options))

    response_body = JSON.parse(response.body)
    response_body['Created']
  end

  # Sets the categories on a prefix to given list of categories.
  # @param [Array<Wbrs::Category | Integer>] category_ids: List of categories or category ids.
  # @param [String] user: The user for this action
  # @param [String] description: A description
  # @return [Integer] id of updated prefix.
  def set_categories(category_array, user:, description: nil)
    category_ids = Wbrs::Category.category_ids(category_array)
    options = { 'prefix_id' => id, 'categories' => category_ids, 'user' => user, 'description' => description }
    response = Wbrs::Prefix.post_request(path: '/v1/cat/rules/edit', body: Wbrs::Prefix.stringkey_params(options))

    response_body = JSON.parse(response.body)
    response_body['Updated']
  end

  # Disables the rules on this prefix.
  # @param [String] user: The user for this action
  def disable(user:)
    options = { 'prefix_id' => id, 'user' => user }
    Wbrs::Prefix.post_request(path: '/v1/cat/rules/disable', body: Wbrs::Prefix.stringkey_params(options))
  end
end
