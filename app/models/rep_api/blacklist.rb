class RepApi::Blacklist < RepApi::Base
  FIELD_NAMES = %w{entry disposition public excluded classifications manual_classifications class_id
                   expiration expired hostname author primary_source metadata seen_by
                   _id _rev first_seen last_seen stale status ip ipi
                   message seen_since_exclude comment}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  validates :entry, :classifications, presence: true

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

  def public?
    public
  end

  def excluded?
    excluded
  end

  def self.classifications
    unless @classifications
      #response = call_json_request(:get, '/blacklist/classifications', body: {})
      response = call_json_request(:get, '/api/v3/classifications/get', body: {})
      @classifications = JSON.parse(response.body)
    end
    @classifications.keys
  end

  def self.detailed_classifications
    unless @classifications
      #response = call_json_request(:get, '/blacklist/classifications', body: {})
      response = call_json_request(:get, '/api/v3/classifications/get', body: {})
      @classifications = JSON.parse(response.body)
    end
    @classifications
  end

  def self.load_from_attributes(attributes)
    new(attributes).tap do |model|
      model.instance_variable_set(:@new_record, false)
    end
  end

  def attributes
    {
        entry: author,
        public: public?,
        excluded: excluded?,
        comment: comment
    }
  end

  def self.load_from_prefetch(data)
    data = JSON.parse(data)
    data.inject({}) do |collection_hash, (entry, value)|
      unless 'NOT_FOUND' == value
        collection_hash[entry] = value.merge('entry' => entry)
      end

      collection_hash
    end.values.map{ |attributes| load_from_attributes(attributes) }
  end

  # Get the blacklist entries from the reputation API
  # This is not a relation and cannot be chained with other relations.
  # example: where(entries: [ 'http://dodgyweb.net/darkweb' ], active: true)
  # @param [Array<String>] entries: List of ip addresses, domains or fully­qualified URLs
  def self.where(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    entries = params.delete('entries')
    raise 'Missing required entries condition' unless entries
    return [] unless entries.present?
    string_array = entries.map {|entry| "entry=#{entry}"}

    #response = call_json_request(:post, '/blacklist/get', body: build_request_body(string_array))
    if conditions[:entries].present?
      conditions[:entry] = conditions[:entries]
      conditions.delete(:entries)
    end

    conditions.keys.each do |key|
      if key != :entry
        conditions.delete(key)
      end
    end

    response = call_json_request(:post, '/api/v3/blocklist/get', body: conditions)

    return response.body if raw == true
    response_body = JSON.parse(response.body)

    #response_body.inject({}) do |collection_hash, (entry, value)|
    #  unless 'NOT_FOUND' == value
    #    collection_hash[entry] = value.merge('entry' => entry)
    #  end

    #  collection_hash
    #end.values.map{ |attributes| load_from_attributes(attributes) }

    entry_response = response_body["entries"][response_body["entries"].keys.first]
    if entry_response["message"].downcase == "entry found."
      entry_data = entry_response["data"]
      attributes = {}
      attributes["classifications"] = entry_data["classifications"] rescue ""
      attributes["metadata"] = entry_data["sources"] rescue ""
      attributes["first_seen"] = entry_data["first_seen"] rescue ""
      attributes["last_seen"] = entry_data["last_seen"] rescue ""
      attributes["primary_source"] = entry_data["primary_source"] rescue ""
      attributes["expiration"] = entry_data["expiration"] rescue ""
      attributes["status"] = entry_data["status"] rescue ""
      attributes["_rev"] = entry_data["rev"] rescue ""
      attributes["excluded"] = entry_data["excluded"] rescue ""
      attributes["public"] = entry_data["public"] rescue ""
      attributes["entry"] = entry_data["entry"] rescue ""
      attributes["manual_classifications"] = entry_data["classifications"] rescue ""
      return load_from_attributes(attributes)
    else
      return []
    end

  rescue RepApi::RepApiNotFoundError
    []
  end

  # Save the blacklist object.
  # To add or update a blacklist entry, set the entry and classifications fields on a Blacklist object,
  # and call this method.
  # The entry field is required and may be an array.
  # The classifications field is required and must be an array.
  # @param [String] author: moniker of who is adding or updating this entry.
  # @param [String] comment:
  # @return [Array<RepApi::Blacklist>] collection of responses with entry, expiration, and message.
  def save!(params = {})
    raise "Validation failed: #{errors.full_messages.join(', ')}" unless valid?

    input = stringkey_params(params)
    raise "Missing parameter: author" unless input.has_key?('author')
    raise "Missing parameter: comment" unless input.has_key?('comment')

    #input = input.to_a
    #input += self.classifications.join(",").split(",").map{ |classification| "classification=#{classification}" }
    #entries = entry.kind_of?(Array) ? entry : [entry]
    #input += entries.map{ |entry_curr| "entry=#{entry_curr}" }

    conditions = {}
    conditions[:source] = input['author'] rescue nil
    conditions[:comment] = input['comment'] rescue nil
    conditions[:classification] = self.classifications rescue nil
    conditions[:entry] = self.entry rescue nil

    #response = call_json_request(:post, '/escalations/add', body: build_request_body(input))

    response = call_json_request(:post, '/api/v3/blocklist/add', body: conditions)
    #@new_record = false


    #blacklist_hash = JSON.parse(response.body).inject({}) do |hash, message|
    #  contained_entry = entries.find{ |entry| message['MSG'].include?(entry) }
    #  case
    #    when message['expiration'].present?
    #      hash[message['entry']] = RepApi::Blacklist.new(entry: message['entry'],
    #                                                     expiration: message['expiration'],
    #                                                     message: message['MSG'],
    #                                                     new_record: false)
    #    when contained_entry
    #      hash[contained_entry] = RepApi::Blacklist.new(entry: contained_entry,
    #                                                    message: message['MSG'],
    #                                                    new_record: true)
    #  end

    #  hash
    #end

    #entries.map do |entry_curr|
    #  key = blacklist_hash.keys.find{ |key_curr| entry_curr.include?(key_curr) }
    #  if key
    #    blacklist_hash[key]
    #  else
    #    RepApi::Blacklist.new(entry: entry_curr,
    #                          new_record: true)
    #  end
    #end

    blocklist_objects = []

    response_hash = JSON.parse(response.body)
    if response_hash["success"]
      response_hash["entries"].keys.each do |key|
        new_record = RepApi::Blacklist.new(entry: key, expiration: response_hash["entries"][key]["data"]["expiration"], message: response_hash["entries"][key]["data"]["message"])
        blocklist_objects << new_record
      end
    end

    blocklist_objects

  end

  def self.create!(attributes)
    new(attributes).tap do |blacklist|
      blacklist.save!
    end
  end

  # deletes a blacklist
  # The entry field is required and may be an array.
  def delete!
    expire
    freeze
    true
  end

  # excludes a blacklist
  # The entry field is required and may be an array.
  def exclude
    entries = entry.kind_of?(Array) ? entry : [entry]
    input = entries.map{ |entry_curr| "entry=#{entry_curr}" }

    response = call_json_request(:post, '/blacklist/exclude', body: build_request_body(input))
    true
  end

  # renews a blacklist
  # The entry field is required and may be an array.
  def renew
    entries = entry.kind_of?(Array) ? entry : [entry]
    input = entries.map{ |entry_curr| "entry=#{entry_curr}" }

    response = call_json_request(:post, '/blacklist/renew', body: build_request_body(input))
    true
  end

  # expires a blacklist
  # The entry field is required and may be an array.
  def expire
    entries = entry.kind_of?(Array) ? entry : [entry]
    #input = entries.map{ |entry_curr| "entry=#{entry_curr}" }

    input = {:entry => entries}

    #response = call_json_request(:post, '/blacklist/expire', body: build_request_body(input))
    response = call_json_request(:post, '/api/v3/blocklist/expire', body: build_request_body(input))

    true
  end

  # Save the blacklist object.
  # @param [Array<String>] hostnames: array of addresses to blacklist.
  # @param [Array<String>] classifications: array of classifications to use for blacklisting.
  # @param [String] author: moniker of who is adding or updating this entry.
  # @param [String] comment: comment to use for blacklist.
  # @return [Array<RepApi::Blacklist>] collection of responses with entry, expiration, and message.
  def self.add_from_hosts(hostnames:, classifications:, author:, comment:)
    blacklist = RepApi::Blacklist.new(entry: hostnames,
                                      classifications: classifications)
    blacklist.save!(author: author, comment: comment)
  end

  # Save the blacklist object.
  # @param [Hash] params "dispute_entry_ids" array of ids, "classifications" array, and "comment".
  # @param [String] username: moniker of who is adding or updating this entry.
  # @return [Array<RepApi::Blacklist>] collection of responses with entry, expiration, and message.
  def self.add_from_params(params, username:)
    dispute_entry_ids = params['dispute_entry_ids']
    entries = []
    if params['entries'].present?
      entries = params['entries'].map {|entry| entry.strip }
    end
    if (dispute_entry_ids.blank? && entries.blank?)
      raise 'Must provide dispute entry ids or url entries'
    end
    if dispute_entry_ids.present?
      entries = dispute_entry_ids.map {|id| DisputeEntry.find(id)}

      reptool_entries = entries.map {|entry| entry.hostlookup}
    else
      reptool_entries = entries
    end

    add_from_hosts(hostnames: reptool_entries,
                   classifications:params['classifications'],
                   author: username,
                   comment: params['comment'])
  end

  def self.delete_from_params(params)
    dispute_entry_ids = params['dispute_entry_ids']
    entries = []
    if params['entries'].present?
      entries = params['entries'].map {|entry| entry.strip }
    end

    if (dispute_entry_ids.blank? && entries.blank?)
      raise 'Must provide dispute entry ids or url entries'
    end
    if dispute_entry_ids.present?
      entries = dispute_entry_ids.map {|id| DisputeEntry.find(id)}

      reptool_entries = entries.map {|entry| entry.hostlookup}
    else
      reptool_entries = entries
    end

    blacklist = RepApi::Blacklist.new(entry: reptool_entries)
    blacklist.delete!
  end

  def self.adjust_from_params(params, username:)
    
    case params['action'].downcase
      when 'active'
        add_from_params(params, username: username)
      when 'expired'
        delete_from_params(params)
      else
        raise "No known action '#{params['action']}'."
    end
  end


  #########
  ## for testing API
  #########

  #arg needs
  #classification
  #entry
  #author
  #comment
  def self.add_reptool_entry(params)
    input = stringkey_params(params)
    raise "Missing parameter: author" unless input.has_key?('author')
    raise "Missing parameter: comment" unless input.has_key?('comment')
    raise "Missing parameter: classification" unless input.has_key?('classification')
    input = input.to_a

    response = call_json_request(:post, '/escalations/add', body: build_request_body(input))

    return JSON.parse(response.body)
  end

  #arg needs
  #entry
  def self.expire_reptool_entry(params)
    input = stringkey_params(params)

    response = call_json_request(:post, '/blacklist/expire', body: build_request_body(input))

    return JSON.parse(response.body)
  end

  def self.health_check
    health_report = {}

    times_to_try = 3
    times_tried = 0
    times_successful = 0
    times_failed = 0
    is_healthy = false

    (1..times_to_try).each do |i|
      begin
        response = call_json_request(:get, '/blacklist/classifications', body: {})

        result = JSON.parse(response.body)
        if result.size > 1
          times_successful += 1
        else
          times_failed += 1
        end
        times_tried += 1
      rescue
        times_failed += 1
        times_tried += 1
      end

    end

    if times_successful > times_failed
      is_healthy = true
    end

    health_report[:times_tried] = times_tried
    health_report[:times_successful] = times_successful
    health_report[:times_failed] = times_failed
    health_report[:is_healthy] = is_healthy

    health_report
  end

end
