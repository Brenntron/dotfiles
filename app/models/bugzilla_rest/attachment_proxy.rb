class BugzillaRest::AttachmentProxy < BugzillaRest::Base

  FIELDS = %i{id data file_name summary content_type comment}
  attr_accessor :bug_id

  def initialize(attrs = {}, api_key:, token:)
    super(compact(indifferent(attrs).slice(*FIELDS)), api_key: api_key, token: token)
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
      response_body = call(:post, "/rest/bug/#{bug_id}/attachment", body: body)
      response_hash = JSON.parse(response_body)

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
