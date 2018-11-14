
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

  def self.default_session
    unless @default_session
      @default_session = BugzillaRest::Session.new
      @default_session.login(Rails.configuration.bugzilla_username, Rails.configuration.bugzilla_password)
    end
    return @default_session
  end

  def build_bug(bug_attrs)
    BugzillaRest::BugProxy.new(bug_attrs, api_key: api_key, token: token)
  end

  def create_bug(bug_attrs, assigned_user: User.vrtincoming)
    BugzillaRest::BugProxy.create!(bug_attrs, assigned_user: assigned_user, api_key: @api_key, token: @token)
  end

  def get_bug(id)
    response = call(:get, "/rest/bug/#{id}")
    response_hash = JSON.parse(response.body)
    bug_attrs = response_hash['bugs'].first

    BugzillaRest::BugProxy.new(bug_attrs, api_key: api_key, token: token)
  end
end
