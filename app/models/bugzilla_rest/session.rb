class BugzillaRest::Session
  def initialize(api_key:, token:)
    byebug
    @api_key = api_key
    @token = token
  end
end
