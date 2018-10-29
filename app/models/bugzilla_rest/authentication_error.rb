class BugzillaRest::AuthenticationError < BugzillaRest::BaseError
  attr_reader :system, :prompt, :fields

  def initialize(msg = 'Bugzilla REST Authentication Error.', code:)
    super
    @system = 'bugzilla'
    @prompt = 'Please sign in using your CEC credentials.'
    @fields = %w{username *password}
  end
end
