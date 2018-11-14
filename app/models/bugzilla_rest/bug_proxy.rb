class BugzillaRest::BugProxy < BugzillaRest::Base

  FIELDS = %i{id product component summary version description opsys platform priority severity
              creator classification assigned_to groups status
              resolution whiteboard creation_time last_change_time qa_contact}

  def initialize(attrs = {}, assigned_user: User.vrtincoming, api_key:, token:)
    assigned_to_email = assigned_user&.email

    super(attrs.reverse_merge('assigned_to' => assigned_to_email), fields: FIELDS, api_key: api_key, token: token)
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
      response = call(:post, '/rest/bug', body: attributes.to_json)
      response_hash = JSON.parse(response.body)

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

  def attachments(reload: false)
    byebug
    unless @attachments && !reload
      response = call(:get, "/rest/bug/#{id}/attachment")
      response_hash = JSON.parse(response.body)

      @attachments = response_hash['bugs'][id.to_s].map do |attachment_hash|
        BugzillaRest::AttachmentProxy.new(attachment_hash, api_key: api_key, token: token)
      end
    end

    @attachments
  end
end
