
##class Webcat::GuardRails
class Webcat::GuardRails < Webcat::Base

  PASS = "PASS"
  FAIL = "FAIL"

  def self.verdict_for_entries(entries)
    begin
      data = {
          "parent" => false,
          "entries" => entries
      }


      response = call_json_request(:post, '/guardrails/check', body: build_request_body(data))

    rescue Exception => e
      Rails.logger.error(e)
      puts e
      Rails.logger.error('Guardrails returned an error response.')
      {error: 'Data Currently Unavailable'}
    end
  end

end
