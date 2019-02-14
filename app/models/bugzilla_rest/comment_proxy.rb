class BugzillaRest::CommentProxy < BugzillaRest::Base

  FIELDS = %i{id time comment text bug_id count attachment_id is_private is_markdown tags creator creation_time}

  # Constructor, typically called through a factory method of this class or a different class.
  def initialize(attrs = {}, api_key:, token:)
    super(attrs, fields: FIELDS, api_key: api_key, token: token)
  end

  def persisted?
    @id.present?
  end

  # Stub method to save attributes set for this object to bugzilla.
  def save!
    body_params = attributes.clone
    bug_id = body_params.delete(:bug_id)
    if persisted?
      comment_id = body_params.delete(:id)
      call(:put, "/rest/bug/comment/#{comment_id}", body: body_params.to_json)
    else
      response = call(:post, "/rest/bug/#{bug_id}/comment", body: body_params.to_json)
      response_hash = JSON.parse(response.body)

      attributes[:id] = response_hash['id']
    end
    id.present?
  end

  # Stub method to construct from given attributes,
  # typically called through a factory method of this class or a different class.
  def self.create!(attrs, api_key:, token:)
    bug_proxy = new(attrs, api_key: api_key, token: token)
    bug_proxy.save!
    bug_proxy
  end
end
