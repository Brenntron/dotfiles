class Wbrs::RuleLink < Wbrs::Base
  attr_accessor :category, :prefix

  delegate :prefix_id, :domain, :is_active, :path, :path_hashed, :port, :protocol, :subdomain, :truncated,
           to: :prefix, :allow_nil => true
  delegate :category_id, :desc_long, :descr, :mnem, to: :category, :allow_nil => true


  def active?
    is_active
  end

  def truncated?
    truncated
  end

  def self.new_from_datum(datum)
    prefix = Wbrs::Prefix.find(datum['prefix_id'])
    unless prefix
      prefix = Wbrs::Prefix.new_from_attributes(datum.slice(*%w{prefix_id domain is_active path path_hashed port
                                                                protocol subdomain truncated}))
    end

    category = Wbrs::Category.find(datum['category'])

    new('category' => category, 'prefix' => prefix)
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
  # @return [Array<Wbrs::Rule>] Array of the results.
  def self.where(conditions = {})
    params = stringkey_params(conditions)
    params['categories'] = params.delete('category_ids') unless params['category_ids'].nil?
    params['is_active'] = params.delete('active') ? 1 : 0 unless params['active'].nil?
    response = post_request(path: '/v1/cat/rules/get', body: params)

    response_body = JSON.parse(response.body)
    response_body['data'].map {|datum| new_from_datum(datum)}
  end
end
