class Wbrs::Prefix < Wbrs::Base
  attr_accessor :prefix_id, :domain, :is_active, :path, :path_hashed, :port, :protocol, :subdomain, :truncated
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
end
