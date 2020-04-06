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

  def self.new_from_related_objects(category_id:, prefix:)
    category = Wbrs::Category.find(category_id)

    new('category' => category, 'prefix' => prefix)
  end

  # Get the rules from given criteria.
  # This is not a relation and cannot be chained with other relations.
  # example: get_where(category_ids = [11], active: true)
  # @param [Array<Integer>] prefix_ids: List of prefixes ids
  # @param [Array<String>] urls: List of URLs
  # @param [Array<Integer>] category_ids: List of prefixes categories
  # @param [Array<Wbrs::Category>] categories: List of prefixes category objects
  # @param [Boolean] active: prefixes active/disable status
  # @param [Integer] limit: Max number of records to return
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::Rule>] Array of the results.
  def self.where(conditions = {})
    params = stringkey_params(conditions)
    category_ids = Wbrs::Category.category_ids_from_params(params)
    params['categories'] = category_ids if category_ids.present?
    params['is_active'] = params.delete('active') ? 1 : 0 unless params['active'].nil?

    response = post_request(path: '/v1/cat/rules/get', body: params)

    response_body = JSON.parse(response.body)
    prefixes = {}
    response_body['data'].map do |datum|
      prefix_id = datum['prefix_id']
      prefix =
          case
            when prefixes[prefix_id]
              prefixes[prefix_id]
            else
              prefixes[prefix_id] = Wbrs::Prefix.new(datum)
          end
      new_from_related_objects(category_id: datum['category'], prefix: prefix)
    end
  end
end
