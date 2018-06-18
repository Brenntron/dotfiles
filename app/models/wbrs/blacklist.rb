class Wbrs::Blacklist < Wbrs::Base
  FIELD_NAMES = %w{entry disposition public excluded classifications manual_classifications class_id
                   expiration hostname author primary_source metadata seen_by comment
                   rev first_seen last_seen stale}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  validates :entry, presence: true

  def initialize(attributes = {})
    super
    @new_record = true
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
    response = call_json_request(:get, '/blacklist/classifications', body: {})

    JSON.parse(response.body)
  end

  def self.load_from_attributes(attributes)
    new(attributes).tap do |model|
      model.instance_variable_set(:@new_record, false)
    end
  end

  def attributes
    { entry: author,
      author: author,
      public: public?,
      excluded: excluded?,
      comment: comment }
  end

  def self.where(conditions = {})
    response = call_json_request(:post, '/blacklist/get', body: stringkey_params(conditions))

    response_body = JSON.parse(response.body)
    response_body.inject({}) do |collection_hash, (entry, value)|
      unless 'NOT_FOUND' == entry
        collection_hash[entry] = value.merge('entry' => entry)
      end

      collection_hash
    end.values.map{ |attributes| load_from_attributes(attributes) }

  rescue Wbrs::WbrsNotFoundError
    []
  end

  def save!
    raise "Validation failed: #{errors.full_messages.join(', ')}" unless valid?

    if new_record?
      call_json_request(:post, '/blacklist/add', body: stringkey_params(attributes))
      @new_record = false
      true
    else
      call_json_request(:post, '/blacklist/add', body: stringkey_params(attributes))
      @new_record = false
      true
    end
  end

  def self.create!(attributes)
    new(attributes).tap do |blacklist|
      blacklist.save!
    end
  end

  def delete(comment:)
    call_json_request(:post, '/blacklist/delete', body: stringkey_params({ entry: self.entry, comment: comment }))
    freeze
  end

  def exclude
    call_json_request(:post, '/blacklist/exclude', body: {entry: self.entry})
  end

  def renew
    call_json_request(:post, '/blacklist/renew', body: {entry: self.entry})
  end

  def expire
    call_json_request(:post, '/blacklist/expire', body: {entry: self.entry})
  end

end
