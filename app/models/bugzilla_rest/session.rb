
class BugzillaRest::Session < BugzillaRest::Base

  # @return [String] bugzilla token
  def login(username, password)
    response_body = call(:get, "/rest/login",
                         send_auth: false,
                         query: { 'login' => username, 'password' => password })
    response_hash = JSON.parse(response_body)

    response_hash['token']
  end

  # @return [Integer] the id of the created bug
  def create_bug(bug_attrs, assigned_user: User.vrtincoming)

    BugzillaRest::BugProxy.create!(bug_attrs, assigned_user: assigned_user, api_key: @api_key, token: @token)
  end
end
