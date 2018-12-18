# Exception class specific to bugzilla REST API 401 responses.
# Contains descriptive information about the system which could not authenticate.
class BugzillaRest::AuthenticationError < BugzillaRest::BaseError
  attr_reader :url, :system, :prompt, :fields

  def initialize(msg = 'Bugzilla REST Authentication Error.', code:)
    super
    @url = '/escalations/api/v1/escalations/bugzilla_rest_login'
    @system = 'bugzilla'
    @prompt = 'Please sign in using your Cisco CEC credentials.'
    @fields = %w{username *password}
  end
end
