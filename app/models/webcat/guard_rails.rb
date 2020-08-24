
##class Webcat::GuardRails
class Webcat::GuardRails < Webcat::Base

  PASS = "green"


  def self.verdict_for_entry(entry, cat_string)
    begin
      data = {
          "parent" => false,
          "entries" => {entry => cat_string}
      }


      response = call_json_request(:post, '/webcat_guardrails/check', body: build_request_body(data))

    rescue Exception => e
      Rails.logger.error(e)
      puts e
      Rails.logger.error('Guardrails returned an error response.')
      {error: 'Data Currently Unavailable'}
    end
  end

end
