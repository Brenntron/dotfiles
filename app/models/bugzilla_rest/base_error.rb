# Exception class specific to bugzilla REST API
# marked for removal but may need for data migration from bugzilla first
class BugzillaRest::BaseError < StandardError
attr_reader :code

  alias_method :status, :code

  def initialize(msg = 'Bugzilla REST API Error', code:)
    super(msg)
    @code = code
  end

end
