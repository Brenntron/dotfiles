class Xena::GuardRails

  TEST_URL = "www.google.com"

  XENA_BASE_URL="https://xena-api.sco.cisco.com/v1/verdicts/all"

  def self.new_request(address)

    full_url = XENA_BASE_URL

    request = HTTPI::Request.new(full_url)
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    request.headers['Authorization'] = "Bearer #{Rails.configuration.xena.api_key}"  #no config code for this right now, as we aren't using xena, but if it's failing in the future, get config sorted out.
    request.headers['Content-Type'] = 'application/json'
    request.body = "{\"items\":[\"#{address}\"]}"
    request
  end


  def self.is_allow_listed?(address)

    request = new_request(address)

    response = JSON.parse(HTTPI.post(request))

    response["is_matched"]

  end

end