class Xbrs::Base
  include ActiveModel::Model

  def self.host
    @host ||= Rails.configuration.xbrs.host || 'localhost'
  end

  def self.consumer_key
    @consumer_key ||= Rails.configuration.xbrs.consumer_key || 'TEST'
  end

  def self.port
    @port ||= Rails.configuration.xbrs.port || 80
  end

  def self.tls_mode
    @tls_mode ||= Rails.configuration.xbrs.tls_mode || 'no-tls'
  end

  def self.gssnegotiate?
    @gssnegotiate ||= Rails.configuration.xbrs.gssnegotiate
  end

  def self.ca_file
    @ca_cert_file ||= Rails.configuration.xbrs.ca_cert_file
  end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def stringkey_params(conditions = {})
    Xbrs::Base.stringkey_params(conditions)
  end

  def self.new_request(path)
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

    request = HTTPI::Request.new("#{protocol}://#{host}:#{port}#{path}?consumer=#{self.consumer_key}")

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

    request
  end

  # TODO replace with new_request
  def self.request(path:, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json

    request
  end

  def self.call_request(method, request)
    case method
      when :post
        if gssnegotiate?
          HTTPI.post(request, :curb)
        else
          HTTPI.post(request)
        end
      else #:get
        if gssnegotiate?
          HTTPI.get(request, :curb)
        else
          HTTPI.get(request)
        end
    end
  end

  # TODO replace with new_request
  def self.make_post_request(path:, body:)
    if gssnegotiate?
      HTTPI.post(request(path: path, body: body), :curb)
    else
      HTTPI.post(request(path: path, body: body))
    end
  end

  def self.request_error_handling(response)
    case
      when 300 > response.code
        response
      when 404 == response.code
        body = JSON.parse(response.body)
        raise Xbrs::XbrsNotFoundError, "HTTP response #{response.code} #{body['Error']}"
      else
        begin
          body = JSON.parse(response.body)
        rescue
          body = response.body
          raise Xbrs::XbrsError, "HTTP response #{response.code} #{body}"
        end
        raise Xbrs::XbrsError, "HTTP response #{response.code} #{body['Error']}"
    end
  end

  def self.call_xbrs_request(method, path, body, raw = false)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json

    response = request_error_handling(call_request(method, request))
    # transform the response body into valid JSON, from the YAML provided by the API
    response_body = response.body.gsub("\n---\n",",")
    response_body = response_body.gsub("---\n", "")
    response_body = response_body.prepend("[").concat("]")
    return response_body if raw == true
    response_body = JSON.parse(response_body)
  end

  def call_xbrs_request(method, path, body:)
    Xbrs::Base.call_xbrs_request(method, path, body: body)
  end

end
