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
