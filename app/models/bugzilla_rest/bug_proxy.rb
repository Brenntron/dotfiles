class BugzillaRest::BugProxy < BugzillaRest::Base

  FIELDS = %i{id product component summary version description opsys platform priority severity
              state creator classification}

  def initialize(attrs = {}, assigned_user: User.vrtincoming, api_key:, token:)
    assigned_to_email = assigned_user&.email
    attributes = compact(indifferent(attrs).slice(*FIELDS).merge('assigned_to' => assigned_to_email))

    super(attributes, api_key: api_key, token: token)
  end

  def id
    attributes[:id]
  end

  def persisted?
    @id.present?
  end

  def save!
    if persisted?
      raise 'update not implemented'
    else
      response_body = call(:post, '/rest/bug', body: attributes.to_json)
      response_hash = JSON.parse(response_body)

      attributes[:id] = response_hash['id']
      id.present?
    end
  end

  def self.create!(attrs, assigned_user: User.vrtincoming, api_key:, token:)
    bug_proxy = new(attrs, assigned_user: assigned_user, api_key: api_key, token: token)
    bug_proxy.save!
    bug_proxy
  end

  def create_attachment!(attachment_attrs)
    AttachmentProxy.create!(attachment_attrs.merge(bug_id: id), api_key: api_key, token: token)
  end
end
