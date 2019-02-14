# Stub class for remote Bugzilla attachment objects using the REST API.
# Begs naming convention of attachment_proxy as such an object.
class BugzillaRest::AttachmentProxy < BugzillaRest::Base

  FIELDS = %i{id data file_name summary content_type comment creator is_private is_obsolete attacher creation_time}
  attr_accessor :bug_id

  # Constructor, typically called through a factory method of this class or a different class.
  def initialize(attrs = {}, api_key:, token:)
    @bug_id = attrs.delete(:bug_id)
    super(attrs, fields: FIELDS, api_key: api_key, token: token)
  end

  def id
    attributes[:id]
  end

  # The file contents of the attachment.
  def file_contents
    Base64.decode64(self.data)
  end

  def persisted?
    @id.present?
  end

  # Stub method to save attributes set for this object to bugzilla.
  def save!
    if persisted?
      raise 'update not implemented'
    else
      body = attributes.merge('ids' => [ bug_id ]).to_json
      response = call(:post, "/rest/bug/#{bug_id}/attachment", body: body)
      response_hash = JSON.parse(response.body)

      attributes[:id] = response_hash['ids'].first
      id.present?
    end
  end

  # Stub method to construct from given attributes,
  # typically called through a factory method of this class or a different class.
  def self.create!(attrs, api_key:, token:)
    attachment_proxy = new(attrs, api_key: api_key, token: token)
    attachment_proxy.save!
    attachment_proxy
  end
end
