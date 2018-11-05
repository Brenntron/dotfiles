class BugzillaRest::BugProxy < BugzillaRest::Base

  FIELDS = %i{id product component summary version description opsys platform priority severity
              state creator classification}
  attr_accessor *FIELDS
  attr_reader :attributes

  def initialize(bug_attrs = {}, assigned_user: User.vrtincoming, api_key:, token:)
    super(api_key: api_key, token: token)

    assigned_to_email = assigned_user&.email
    @attributes = compact(indifferent(bug_attrs).slice(*FIELDS).merge('assigned_to' => assigned_to_email))
  end

  def id
    attributes[:id]
  end

  def persisted?
    @id.blank?
  end

  def save!
    if persisted?
      response_body = call(:post, '/rest/bug', query: attributes)
      response_hash = JSON.parse(response_body)

      attributes[:id] = response_hash['id']
      id.present?
    else
      raise 'update not implemented'
    end
  end

  def self.create!(bug_attrs, assigned_user: User.vrtincoming, api_key:, token:)
    bug_proxy = new(bug_attrs, assigned_user: assigned_user, api_key: api_key, token: token)
    bug_proxy.save!
    bug_proxy
  end

  def respond_to?(method_sym, include_private = false)
    byebug
    case
    when FIELDS.include?(method_sym)
      true
    when /\A(?<field_name>.*)=\z/ !~ method_sym.to_s
      super
    when FIELDS.include?(field_name)
      true
    else
      super
    end
  end

  def method_missing(method_sym, *arguments, &block)
    byebug
    case
    when FIELDS.include?(method_sym)
      attributes[FIELDS]
    when /\A(?<field_name>.*)=\z/ !~ method_sym.to_s
      super
    when FIELDS.include?(field_name)
      attributes[field_name] = arguments[0]
    else
      super
    end
  end
end
