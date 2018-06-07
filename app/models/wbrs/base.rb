class Wbrs::Base
  include ActiveModel::Model

  def self.host
    @host ||= Rails.configuration.wbrs.host
  end

  def self.port
    @port ||= Rails.configuration.wbrs.port
  end

  def self.tls_mode
    @tls_mode ||= Rails.configuration.wbrs.tls_mode
  end

  def self.gssnegotiate?
    @gssnegotiate ||= Rails.configuration.wbrs.gssnegotiate
  end

  def self.ca_file
    @ca_cert_file ||= Rails.configuration.wbrs.ca_cert_file
  end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def self.request(path:, body:)
    raise 'Path required' unless path.present?
    raise 'Path must start with slash (/)' unless '/' == path[0]

    protocol =
        case tls_mode
          when 'verify-peer'
            'https'
          when 'verify-none'
            'https'
          else #no-tls
            'http'
        end

    request = HTTPI::Request.new("#{protocol}://#{host}:#{port}#{path}")

    case tls_mode
      when 'verify-peer'
        request.ssl = true
        request.auth.ssl.verify_mode = :peer
        request.auth.ssl.ca_cert_file = ca_cert_file #this will be nil for Heroku apps
      when 'verify-none'
        request.ssl = true
        request.auth.ssl.verify_mode = :none
      else #no-tls
        request.ssl = false
    end

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json
    request
  end

  def self.make_get_request(path:, body:)
    if gssnegotiate?
      HTTPI.get(request(path: path, body: body), :curb)
    else
      HTTPI.get(request(path: path, body: body))
    end
  end

  def self.make_post_request(path:, body:)
    if gssnegotiate?
      HTTPI.post(request(path: path, body: body), :curb)
    else
      HTTPI.post(request(path: path, body: body))
    end
  end

  def self.request_error_handling(response)
    if 300 > response.code
      response
    else
      body = JSON.parse(response.body)
      raise "HTTP response #{response.code} #{body['Error']}"
    end
  end

  def self.get_request(path:, body:)
    request_error_handling(make_get_request(path: path, body: body))
  end

  def self.post_request(path:, body:)
    request_error_handling(make_post_request(path: path, body: body))
  end
end
