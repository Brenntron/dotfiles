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

end

