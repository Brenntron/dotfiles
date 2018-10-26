class BugzillaRest::BugId < BugzillaRest::Base

  attr_reader :id

  def initialize(bug_id, api_key:, token:)
    super(api_key: api_key, token: token)
    @id = bug_id
  end

end
