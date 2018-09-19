class Bridge::DirectRequest < HTTPI::Request
  def self.new_from_path(path)

    peakebridge = Rails.configuration.peakebridge

    protocol =
        case peakebridge.verify_mode
        when 'verify-peer'
          'https'
        when 'verify-none'
          'https'
        else #no-tls
          'http'
        end

    url = "#{protocol}://#{peakebridge.host}:#{peakebridge.port}#{path}"
    new(url).tap do |request|
      case peakebridge.verify_mode
      when 'verify-peer'
        request.ssl = true
        request.auth.ssl.verify_mode = :peer
        request.auth.ssl.ca_cert_file = peakebridge.ca_cert_file #this will be nil for Heroku apps
      when 'verify-none'
        request.ssl = true
        request.auth.ssl.verify_mode = :none
      else #no-tls
        request.ssl = false
      end
    end
  end

  def self.poll(addressee)
    request = new_from_path("/poll/#{addressee}")
    HTTPI.get(request, :curb)
  end
end
