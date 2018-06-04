class Wbrs::Rule < Wbrs::Base
  attr_accessor :category_id, :desc_long, :descr, :domain, :is_active, :mnem, :path, :path_hashed, :port, :prefix_id,
                :protocol, :subdomain, :truncated

  def active?
    is_active
  end

  def truncated?
    truncated
  end

  def self.new_from_datum(datum)
    datum['category_id'] = datum.delete('category')
    new(datum)
  end

  # Get the rules from given criteria.
  # @param [Array<Integer>] prefix_ids: List of prefixes ids
  # @param [Array<String>] urls: List of URLs
  # @param [Array<Integer>] categories: List of prefixes categories
  # @param [Boolean] active: prefixes active/disable status
  # @param [Integer] limit: Max number of records to return
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::Rule>] Array of the results.
  def self.get_where(conditions = {})
    params = stringkey_params(conditions)
    params['is_active'] = params.delete('active') ? 1 : 0
    response = post_request(path: '/v1/cat/rules/get', body: params)

    response_body = JSON.parse(response.body)
    response_body['data'].map {|datum| new_from_datum(datum)}
  end
end
