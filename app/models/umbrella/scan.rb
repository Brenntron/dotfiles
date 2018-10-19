class Umbrella::Scan
  def self.new_request(address)
    request = HTTPI::Request.new(Rails.configuration.umbrella.url)
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    request.headers['Authorization'] = "Bearer #{Rails.configuration.umbrella.api_key}"
    request.headers['Content-Type'] = 'application/json'
    request.body = [ address ].to_json
    request
  end

  def self.scan(address:)
    request = new_request(address)
    HTTPI.post(request)
  end
end
