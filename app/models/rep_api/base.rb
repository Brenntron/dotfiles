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
    RepApi::Base.stringkey_params(conditions)
  end

  def self.build_request_body(input)
    case input
      when Array
        string_array = input.map do |element|
          case
            when element.kind_of?(Array) && 1 == element.count
              element.first.to_s
            when element.kind_of?(Array) && 2 == element.count
              "#{element[0]}=#{element[1]}"
            else
              element.to_s
          end
        end
        string_array.join('&')
      else #when String
        input
    end
  end

  def build_request_body(input)
    RepApi::Base.build_request_body(input)
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
      request.auth.gssnegotiate
    end

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
    request = new_request(path)

    request.headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    request.body =
        case body
          when Hash
            body.map{ |key, value| "#{key}=#{value}" }.join('&')
          when Array
            body.join('&')
          else
            body
        end

    request_error_handling(call_request(method, request))
  end

  def call_json_request(method, path, body:)
    RepApi::Base.call_json_request(method, path, body: body)
  end
end
