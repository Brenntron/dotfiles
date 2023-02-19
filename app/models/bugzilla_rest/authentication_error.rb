# Exception class specific to bugzilla REST API 401 responses.
# Contains descriptive information about the system which could not authenticate.
class BugzillaRest::AuthenticationError < BugzillaRest::BaseError
  attr_reader :url, :system, :prompt, :fields

end
