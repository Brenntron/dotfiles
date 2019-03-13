# Starting factory class for remote bugzilla resources using REST API.
#
# Initialize using Base class initializer passing api_key and token arguments.
#
#     # @param [String] api_key
#     # @param [String] token
#     # @return [BugzillaRest::Session]
#     BugzillaRest::Session.new(api_key:, token:)
#
# Other stubs for remote bugzilla resources, particularly the BugProxy, can be constructed from this object.
#
class BugzillaRest::Session < BugzillaRest::Base

  # @return [String] bugzilla token
  def login(username, password)
    response = call(:get, "/rest/login",
                         send_auth: false,
                         query: { 'login' => username, 'password' => password })
    response_hash = JSON.parse(response.body)

    @token = response_hash['token']
    return @token
  end

  # @return [BugzillaRest::Session] the session for the analyst-console service account.
  def self.default_session
    unless @default_session
      if Rails.configuration.bugzilla_api_key
        @default_session = BugzillaRest::Session.new(api_key: Rails.configuration.bugzilla_api_key, token: nil)
      else
        @default_session = BugzillaRest::Session.new(api_key: nil, token: nil)
        @default_session.login(Rails.configuration.bugzilla_username, Rails.configuration.bugzilla_password)
      end
    end
    return @default_session
  end

  # Constructs a BugProxy without any updates to bugzilla.
  #
  # This is useful to populate attributes and then save to bugzilla.
  # You can also just set the id attribute, and use methods which will then relate to the bug with that id.
  #
  # @param [Hash] bug_attrs Any attributes you want to set on the (in memory) object.
  # @return [BugzillaRest::BugProxy] The stub for the remote bug resource in bugzilla.
  def build_bug(bug_attrs)
    BugzillaRest::BugProxy.new(bug_attrs, api_key: api_key, token: token)
  end

  # Constructs a BugProxy and updates to bugzilla.
  #
  # @param [Hash] bug_attrs Any attributes you want to set on the (in memory) object.
  # @return [BugzillaRest::BugProxy] The stub for the remote bug resource in bugzilla.
  def create_bug(bug_attrs, assigned_user: User.vrtincoming)
    BugzillaRest::BugProxy.create!(bug_attrs, assigned_user: assigned_user, api_key: @api_key, token: @token)
  end

  # Constructs a BugProxy for a bug found from the id.
  # @param [Integer] bug_id the bug id.
  # @return [BugzillaRest::BugProxy] The stub for the remote bug resource in bugzilla.
  def get_bug(bug_id)
    response = call(:get, "/rest/bug/#{bug_id}")
    response_hash = JSON.parse(response.body)
    bug_attrs = response_hash['bugs'].first

    BugzillaRest::BugProxy.new(bug_attrs, api_key: api_key, token: token)
  end

  # Searches for all bugs matching the search criteria.
  # @param [Hash] query_hash the search criteria.
  # @return [Array<BugzillaRest::BugProxy>] array of bug proxies for resulting bugs.
  def search_bugs(query_hash)
    response = call(:get, "/rest/bug", query: query_hash)
    response_hash = JSON.parse(response.body)

    response_hash['bugs'].map do |bug_attrs|
      BugzillaRest::BugProxy.new(bug_attrs, api_key: api_key, token: token)
    end
  end

  # Constructs an AttachmentProxy for an attachment from the id.
  # @param [Integer] attachment_id the attachment id.
  # @return [BugzillaRest::AttachmentProxy] The stub for the remote attachment resource in bugzilla.
  def get_attachment(attachment_id)
    response = call(:get, "/rest/bug/attachment/#{attachment_id}")
    response_hash = JSON.parse(response.body)
    attachment_attrs = response_hash['attachments'].values.first

    BugzillaRest::AttachmentProxy.new(attachment_attrs, api_key: api_key, token: token)
  end

  def self.logged_in?(session)
    api_key = session.api_key
    token = session.token

    if api_key.present? || token.present?
      return true
    else
      return false
    end
  end

end
