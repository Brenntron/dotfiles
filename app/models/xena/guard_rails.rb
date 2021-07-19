class Xena::GuardRails

  TEST_URL = "www.google.com"

  XENA_BASE_URL="https://xena-api.sco.cisco.com/v1/verdicts/all"

  def self.new_request(address)

    full_url = XENA_BASE_URL

    request = HTTPI::Request.new(full_url)
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    #request.headers['Authorization'] = "Bearer #{Rails.configuration.xena.api_key}"
    request.headers['Authorization'] = "Bearer dbb2da7f75fc69f4ae539b4721f23aed19ba2bd8dda18f043928c5b14ca03373"
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