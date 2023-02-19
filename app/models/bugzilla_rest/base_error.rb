# Exception class specific to bugzilla REST API
class BugzillaRest::BaseError < StandardError
  attr_reader :code

  alias_method :status, :code


end
