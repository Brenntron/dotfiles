# Stub class for remote Bugzilla attachment objects using the REST API.
# Begs naming convention of attachment_proxy as such an object.
class BugzillaRest::AttachmentProxy < BugzillaRest::Base

  FIELDS = %i{id data file_name summary content_type comment creator is_private is_obsolete attacher creation_time}

end
