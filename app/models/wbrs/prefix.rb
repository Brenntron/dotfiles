class Wbrs::Prefix < Wbrs::Base
  FIELD_NAMES = %w{prefix_id domain is_active path path_hashed port protocol subdomain truncated}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS
  class << self
    attr_reader :all_hash
  end
  @all_hash = {}

  alias_method(:id, :prefix_id)

  def self.new_from_attributes(attributes)
    prefix_id = attributes['prefix_id'] || attributes['id']
    @all_hash[prefix_id] = new(attributes)
  end

  # Get a prefix by id
  # @param [Integer] id the prefix id
  # @return [Wbrs::Prefix] the prefix
  def self.find(id)
    @all_hash[id]
  end

  def self.add_rule(attributes)
    response = post_request(path: '/v1/cat/rules/add', body: stringkey_params(attributes))

    response_body = JSON.parse(response.body)
    response_body['Created']
  end

  def self.edit_rule(attributes)
    response = post_request(path: '/v1/cat/rules/edit', body: stringkey_params(attributes))

    response_body = JSON.parse(response.body)
    response_body['Updated']
  end

  def self.disable_rule(attributes)
    response = post_request(path: '/v1/cat/rules/disable', body: stringkey_params(attributes))

    response_body = JSON.parse(response.body)
    response_body
  end

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
end
