class BugzillaRest::AttachmentProxy < BugzillaRest::Base

  FIELDS = %i{id data file_name summary content_type comment is_private is_obsolete attacher}
  attr_accessor :bug_id

  def initialize(attrs = {}, api_key:, token:)
    super(attrs, fields: FIELDS, api_key: api_key, token: token)
    @bug_id = attrs[:bug_id]
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
      body = attributes.merge('ids' => [ bug_id ]).to_json
      response = call(:post, "/rest/bug/#{bug_id}/attachment", body: body)
      response_hash = JSON.parse(response.body)

      attributes[:id] = response_hash['ids'].first
      id.present?
    end
  end

  def self.create!(attrs, api_key:, token:)
    attachment_proxy = new(attrs, api_key: api_key, token: token)
    attachment_proxy.save!
    attachment_proxy
  end

end
