class RepApi::Base
  include ActiveModel::Model

  def self.host
    @host ||= Rails.configuration.rep_api.host || 'localhost'
  end

  def self.port
    @port ||= Rails.configuration.rep_api.port || 443
  end

  def self.tls_mode
    @tls_mode ||= Rails.configuration.rep_api.tls_mode
  end

  def self.gssnegotiate?
    @gssnegotiate ||= Rails.configuration.rep_api.gssnegotiate
  end

  def self.ca_file
    @ca_cert_file ||= Rails.configuration.rep_api.ca_cert_file
  end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def stringkey_params(conditions = {})
    Wbrs::Base.stringkey_params(conditions)
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

    url = "#{protocol}://#{host}:#{port}#{path}"
    request = HTTPI::Request.new(url)

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

    if gssnegotiate?
      Curl::Easy.new(url) do |curl|
        byebug
        # curl.cacert = @http.auth.ssl.ca_cert_file
        curl.ssl_verify_peer = false
        curl.use_ssl = 1
        curl.http_auth_types = "Negotiate"
        curl.ssl_verify_host = 0
      end
    end
    request.auth.basic('marlpier', '')

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
    byebug
    # case method
    #   when :post
    #     if gssnegotiate?
    #       HTTPI.post(request, :curb)
    #     else
    #       HTTPI.post(request)
    #     end
    #   else #:get
    #     if gssnegotiate?
    #       HTTPI.get(request, :curb)
    #     else
    #       HTTPI.get(request)
    #     end
    # end
    HTTPI.get(request, :curb)
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
        raise RepApi::RepApiNotFoundError, "HTTP response #{response.code}"
      else
        raise RepApi::RepApiError, "HTTP response #{response.code}"
    end
  end

  def self.call_json_request(method, path, body:)
    byebug
    url = "https://#{host}:#{port}#{path}"
    request = HTTPI::Request.new(url)

    case 'verify-none'
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
    request.auth.gssnegotiate

    # request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
    # request.body = body.to_json
    request.body = '[]'


    response = HTTPI.get(request, :curb)
    byebug

    # request_error_handling(call_request(method, request))
    request_error_handling(response)
  end

  def call_json_request(method, path, body:)
    Wbrs::Base.call_json_request(method, path, body: body)
  end

  # TODO replace with call_json_request
  def self.post_request(path:, body:)
    request_error_handling(make_post_request(path: path, body: body))
  end
end
