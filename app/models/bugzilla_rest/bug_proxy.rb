# Stub class for remote Bugzilla bug objects using the REST API.
# Begs naming convention of bug_proxy as such an object.
class BugzillaRest::BugProxy < BugzillaRest::Base

  FIELDS = %i{id product component summary version description opsys platform priority severity
              creator classification assigned_to groups status
              resolution whiteboard creation_time last_change_time qa_contact depends_on}

  # Constructor, typically called through a factory method of this class or a different class.

end
