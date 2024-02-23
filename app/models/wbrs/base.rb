class Wbrs::Base
  include ActiveModel::Model
  AdhocErrorResponse = Struct.new(:body, :error, :code)
  def self.host
    @host ||= Rails.configuration.wbrs.host || 'localhost'
  end

  def self.port
    @port ||= Rails.configuration.wbrs.port || 80
  end

  def self.verify_mode
    @verify_mode ||= Rails.configuration.wbrs.verify_mode
  end

  def self.gssnegotiate?
    @gssnegotiate ||= Rails.configuration.wbrs.gssnegotiate
  end

  def self.ca_cert_file
    @ca_cert_file ||= Rails.configuration.wbrs.ca_cert_file
  end

  def self.read_timeout
    @read_timeout ||= Rails.configuration.wbrs.read_timeout
  end
  def self.open_timeout
    @open_timeout ||= Rails.configuration.wbrs.open_timeout
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
        case verify_mode
          when 'verify-peer'
            'https'
          when 'verify-none'
            'https'
          else #no-tls
            'https'
        end
    port = 443
    request = HTTPI::Request.new("#{protocol}://#{host}:#{port}#{path}")

    request.read_timeout = read_timeout
    request.open_timeout = open_timeout

    case verify_mode
      when 'verify-peer'
        request.ssl = true
        request.auth.ssl.verify_mode = :none
        #request.auth.ssl.ca_cert_file = ca_cert_file #this will be nil for Heroku apps
      when 'verify-none'
        request.ssl = true
        request.auth.ssl.verify_mode = :none
      else #no-tls
        request.ssl = true
        #added this here for new ruleAPI auth requirements.
        request.auth.ssl.verify_mode = :none
    end

    request
  end

  # TODO replace with new_request
  def self.request(path:, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json", "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}" }
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
    begin
      if gssnegotiate?
        HTTPI.post(request(path: path, body: body), :curb)
      else
        HTTPI.post(request(path: path, body: body))
      end
    rescue => except
      Rails.logger.error("Something is wrong with RuleAPI connection")
      Rails.logger.error(except)
      Rails.logger.error(except.backtrace.join("\n"))

      return_response = AdhocErrorResponse.new
      return_response.body = "{\"data\":[]}"
      return_response.error = "RuleApi cannot be reached"
      return_response.code = 404
      return_response
    end
  end

  def self.request_error_handling(response)
    case
    when 300 > response.code
      response
    when 404 == response.code
      body = JSON.parse(response.body) rescue nil
      error = body ? body['Error'] : nil
      #raise Wbrs::WbrsNotFoundError, "HTTP response #{response.code} #{error}"
      #{:error => "Wbrs Not Found Error", :message => "HTTP response #{response.code} #{error}"}.to_json
      Rails.logger.error("HTTP response #{response.code} #{error}")
      return_response = AdhocErrorResponse.new
      return_response.body = "{\"data\":[]}"
      return_response.error = "HTTP response #{response.code} #{error}"
      return_response.code = response.code
      return_response
    else
      body = JSON.parse(response.body) rescue nil
      error = body ? body['Error'] : nil
      #raise Wbrs::WbrsError, "HTTP response #{response.code} #{error}"
      #{:error => "Wbrs Error", :message => "HTTP response #{response.code} #{error}"}.to_json
      Rails.logger.error("HTTP response #{response.code} #{error}")
      return_response = AdhocErrorResponse.new
      return_response.body = "{\"data\": []}"
      return_response.error = "HTTP response #{response.code} #{error}"
      return_response.code = response.code
      return_response
    end
  end

  def self.call_json_request(method, path, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json", "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}" }

    request.body = body.to_json
    begin
      request_error_handling(call_request(method, request))
    rescue => except
      Rails.logger.error("Something is wrong with RuleAPI connection")
      Rails.logger.error(except)
      Rails.logger.error(except.backtrace.join("\n"))

      return_response = AdhocErrorResponse.new
      return_response.body = "{\"data\":[]}"
      return_response.error = "RuleApi cannot be reached"
      return_response
    end
  end

  def call_json_request(method, path, body:)
    Wbrs::Base.call_json_request(method, path, body: body)
  end

  # TODO replace with call_json_request
  def self.post_request(path:, body:)
    request_error_handling(make_post_request(path: path, body: body))
  end
end
