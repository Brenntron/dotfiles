class BugzillaRest::CommentProxy < BugzillaRest::Base

  FIELDS = %i{id time comment text bug_id count attachment_id is_private is_markdown tags creator creation_time}

  # Constructor, typically called through a factory method of this class or a different class.

end
