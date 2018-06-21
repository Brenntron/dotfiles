class RepApi::Whitelist < Wbrs::Base
  FIELD_NAMES = %w{entry source range ident comment}
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

  def self.load_from_attributes(attributes)
    new(attributes).tap do |model|
      model.instance_variable_set(:@new_record, false)
    end
  end

  def attributes
    { entry: entry, source: source, range: range, ident: ident, comment: comment }
  end

  def self.where(conditions = {})
    response = call_json_request(:post, '/whitelist/get', body: stringkey_params(conditions))

    response_body = JSON.parse(response.body)
    response_body.inject({}) do |collection_hash, (entry, value)|
      unless 'NOT_FOUND' == entry
        collection_hash[entry] = value.merge('entry' => entry)
      end

      collection_hash
    end.values.map{ |attributes| load_from_attributes(attributes) }

  rescue RepApi::RepApiNotFoundError
    []
  end

  def save!
    raise "Validation failed: #{errors.full_messages.join(', ')}" unless valid?

    if new_record?
      call_json_request(:post, '/whitelist/add', body: stringkey_params(attributes))
      @new_record = false
      true
    else
      raise RepApi::RepApiError, 'Cannot add an existing entry!'
    end
  end

  def self.create!(attributes)
    new(attributes).tap do |whitelist|
      whitelist.save!
    end
  end

  def delete(comment:)
    call_json_request(:post, '/whitelist/delete', body: stringkey_params({ entry: self.entry, comment: comment }))
    freeze
  end

end
