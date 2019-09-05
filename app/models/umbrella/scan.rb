class Umbrella::Scan
  def self.new_request(address)
    request = HTTPI::Request.new(Rails.configuration.umbrella.url)
    request.read_timeout = Rails.configuration.umbrella.read_timeout
    request.open_timeout = Rails.configuration.umbrella.open_timeout
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    request.headers['Authorization'] = "Bearer #{Rails.configuration.umbrella.api_key}"
    request.headers['Content-Type'] = 'application/json'
    request.body = [ address ].to_json
    request
  end

  def self.scan_result(address:)
    request = new_request(address)
    HTTPI.post(request)
  end
end
