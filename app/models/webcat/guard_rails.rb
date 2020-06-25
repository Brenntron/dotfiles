
class Webcat::GuardRails
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.guard_rails
  set_default_request_type :json

  PASS = "PASS"
  FAIL = "FAIL"

  def self.verdict_for_entries(entries)
    begin
      data = {
          "parent" => false,
          "entry" => [entries]
      }
      self.class.call_request_parsed(:post, "/guardrails/check", input: data)


    rescue JSON::ParserError
      Rails.logger.error('Guardrails returned invalid JSON.')
      {error: 'Invalid Entries'}
    rescue ApiRequester::ApiRequester::ApiRequesterNotAuthorized
      Rails.logger.error('Guardrails returned an "Unauthorized" response.')
      {error: 'Unauthorized'}
    rescue
      Rails.logger.error('Guardrails returned an error response.')
      {error: 'Data Currently Unavailable'}
    end
  end

end
