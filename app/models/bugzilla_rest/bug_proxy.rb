# Stub class for remote Bugzilla bug objects using the REST API.
# Begs naming convention of bug_proxy as such an object.
class BugzillaRest::BugProxy < BugzillaRest::Base

  FIELDS = %i{id product component summary version description opsys platform priority severity
              creator classification assigned_to groups status
              resolution whiteboard creation_time last_change_time qa_contact depends_on}

  # Constructor, typically called through a factory method of this class or a different class.
  def initialize(attrs = {}, assigned_user: User.vrtincoming, api_key:, token:)
    assigned_to_email = assigned_user&.email

    super(attrs.reverse_merge('assigned_to' => assigned_to_email), fields: FIELDS, api_key: api_key, token: token)
  end

  def id
    attributes[:id]
  end

  def persisted?
    id.present?
  end

  # Method to save attributes set for this object to bugzilla.
  def save!
    if persisted?
      put_attrs = attributes.clone
      put_id = put_attrs.delete(:id)

      depends_on = put_attrs.delete(:depends_on)
      put_attrs[:depends_on] = { 'add' => depends_on } if depends_on.present?

      response = call(:put, "/rest/bug/#{put_id}", body: put_attrs.to_json)
      response_hash = JSON.parse(response.body)

      attributes[:last_change_time] = response_hash['bugs']&.first['last_change_time']
      response_hash['bugs'].any? { |bug_attrs| bug_attrs['id'] }
    else
      response = call(:post, '/rest/bug', body: attributes.to_json)
      response_hash = JSON.parse(response.body)

      attributes[:id] = response_hash['id']
      id.present?
    end
  end

  # Stub method to construct stub from given attributes,
  # typically called through a factory method of this class or a different class.
  def self.create!(attrs, assigned_user: User.vrtincoming, api_key:, token:)
    bug_proxy = new(attrs, assigned_user: assigned_user, api_key: api_key, token: token)
    bug_proxy.save!
    bug_proxy
  end

  # Stub method to update from given attributes,
  # @param [Hash] attrs attributes to update.
  def update!(attrs)
    merge_attributes(attrs)
    save!
  end

  # Factory method to construct a comment proxy from given attributes.
  # Does not save the data to bugzilla.
  # Cleans input to omit nil values, ignore keys which are not valid attributes, and any needed translation.
  # @param [Hash] comment_attrs the given attributes.
  def build_comment(comment_attrs)
    BugzillaRest::CommentProxy.new(comment_attrs.merge(bug_id: id), api_key: api_key, token: token)
  end

  # Factory method to construct a comment proxy from given attributes.
  # Saves the data to bugzilla.
  # Cleans input to omit nil values, ignore keys which are not valid attributes, and any needed translation.
  # @param [Hash] comment_attrs the given attributes.
  def create_comment!(comment_attrs)
    CommentProxy.create!(comment_attrs, api_key: api_key, token: token)
  end

  # Stub method to get collection of comment proxies for this bug's comments.
  # @param [Boolean] reload set to true to refresh data from bugzilla instead of using cached data.
  # @return [Array<BugzillaRest::CommentProxy>] array of comment proxies (stubs) for bugzilla comments.
  def comments(reload: false)
    unless @comments && !reload
      response = call(:get, "/rest/bug/#{id}/comment")
      response_hash = JSON.parse(response.body)

      @comments = response_hash['bugs'][id.to_s]['comments'].map do |comment_hash|
        BugzillaRest::CommentProxy.new(comment_hash, api_key: api_key, token: token)
      end
    end

    @comments
  end

  # Creates an attachment on bugzilla for this bug.
  # @param [Hash] attachment_attrs Attachment attributes
  # @return [BugzillaRest::AttachmentProxy] a stub for the bugzilla attachment resource.
  def create_attachment!(attachment_attrs)
    BugzillaRest::AttachmentProxy.create!(attachment_attrs.merge(bug_id: id), api_key: api_key, token: token)
  end

  # Stub method to get collection of attachment proxies for this bug's attachments.
  # @param [Boolean] reload set to true to refresh data from bugzilla instead of using cached data.
  # @return [Array<BugzillaRest::AttachmentProxy>] array of attachment proxies (stubs) for bugzilla attachments.
  def attachments(reload: false)
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
