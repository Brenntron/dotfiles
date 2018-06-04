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
end
