
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
    assigned_to = assigned_user&.email
    bugzilla_bug_options =
        bug_attrs.to_h.slice(*%w{product component summary version description opsys platform priority severity
                                 state creator classification})
            .reject { |key, value| value.nil? }
            .merge('assigned_to' => assigned_to)

    response_body = call(:post, '/rest/bug', query: bugzilla_bug_options)
    response_hash = JSON.parse(response_body)

    BugId.new(response_hash['id'], api_key: @api_key, token: @token)
  end
end
