class RepApi::Whitelist < RepApi::Base
  FIELD_NAMES = %w{entry source range ident comment message}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  validates :entry, presence: true

  def initialize(attributes = {})
    if attributes.keys.present?
      attributes.keys.each do |attr|
        if !FIELD_NAMES.include?(attr)
          self.class.module_eval { attr_accessor attr.to_sym}
        end
      end
    end
    @new_record = attributes.has_key?(:new_record) ? attributes.delete(:new_record) : true
    super
  end

  def new_record?
    @new_record
  end

  def self.load_from_attributes(attributes)
    new(attributes).tap do |model|
      model.instance_variable_set(:@new_record, false)
    end
  end

  def attributes
    { entry: entry, source: source, range: range, ident: ident, comment: comment }
  end

  # TODO: look into wonkiness issues.
  # Get the whitelist entries from the reputation API
  # This is not a relation and cannot be chained with other relations.
  # example: get_where(entries: [ 'http://dodgyweb.net/darkweb' ], active: true)
  # @param [Array<String>] entries: List of ip addresses, domains or fully­qualified URLs
  def self.where(conditions = {})
    params = stringkey_params(conditions)
    entries = params.delete('entries')
    raise 'Missing required entries condition' unless entries
    return [] unless entries.present?
    string_array = entries.map {|entry| "entry=#{entry}"}

    response = call_json_request(:post, '/whitelist/get', body: build_request_body(string_array))

    response_body = JSON.parse(response.body)
    response_body.inject({}) do |collection_hash, (entry, value)|
      unless 'NOT_FOUND' == value
        value = value.kind_of?(Array) ? value.first : value
        collection_hash[entry] = value.merge('entry' => entry)
      end

      collection_hash
    end.values.map{ |attributes| load_from_attributes(attributes) }

  rescue RepApi::RepApiNotFoundError
    []
  end

  # Save the whitelist object.
  # To add or update a whitelist entry, set the entry and classifications fields on a Blacklist object,
  # and call this method.
  # The entry field is required and may *not* be an array.
  # @param [String] author moniker of who is adding or updating this entry.
  # @param [String] comment
  # @return [Array<RepApi::Blacklist>] collection of responses with entry, expiration, and message.
  def save!(params = {})
    raise "Validation failed: #{errors.full_messages.join(', ')}" unless valid?

    input = stringkey_params(params)
    raise "Missing parameter: author" unless input.has_key?('author')
    raise "Missing parameter: comment" unless input.has_key?('comment')

    input = input.to_a
    input << "entry=#{self.entry}"

    response = call_json_request(:post, '/whitelist/add', body: build_request_body(input))
    @new_record = false
    self.message = JSON.parse(response.body)['MSG']
    self
  end

  def self.create!(attributes)
    new(attributes).tap do |whitelist|
      whitelist.save!
    end
  end

  # deletes a whitelist
  # The entry field is required and may be an array.
  def delete!(params = {})
    input = stringkey_params(params)
    raise "Missing parameter: comment" unless input.has_key?('comment')

    input = input.to_a
    input << "entry=#{self.entry}"

    response = call_json_request(:post, '/whitelist/delete', body: build_request_body(input))
    freeze
    true
  end
  #old format:
  # {"google.com"=>{"hostname"=>"google.com", "expiration"=>"NEVER", "_id"=>"57165ecb673ca5a24b1b66db", "status"=>"ACTIVE", "ident"=>"", "source"=>"From whitelist_ips in PostgreSQL", "comment"=>""}}
  #new format:
  # {"google.com"=>{"found"=>true, "result"=>{"_id"=>{"$oid"=>"57165ecb673ca5a24b1b66db"}, "comment"=>"", "hostname"=>"google.com", "ident"=>"", "source"=>"From whitelist_ips in PostgreSQL"}}}
  
  def self.get_whitelist_info(conditions = {})

    if conditions[:entries].present?
      conditions[:entry] = conditions[:entries]
      conditions.delete(:entries)
    end


    response = call_json_request(:post, '/api/v3/allowlist/get', body: conditions)

    response_body = JSON.parse(response.body)

    new_response = {}
    response_body.keys.each do |host|
      if response_body[host]["found"] == false
        raise RepApi::RepApiNotFoundError, "HTTP response 404"
      end
      new_response[host] = {}
      new_response[host]["status"] = "ACTIVE"
      new_response[host]["_id"] = response_body[host]["result"]["_id"]["$oid"]
      new_response[host]["source"] = response_body[host]["result"]["source"]
      new_response[host]["comment"] = response_body[host]["result"]["comment"]
      new_response[host]["ident"] = response_body[host]["result"]["ident"]
      new_response[host]["hostname"] = response_body[host]["result"]["hostname"]
      new_response[host]["expiration"] = "NEVER"
    end

    new_response
  end


end
