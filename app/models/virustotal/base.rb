class Virustotal::Base
  include ActiveModel::Model

  def self.host
    @host ||= Rails.configuration.virustotal.host || 'localhost'
  end

  def self.api_key
    @consumer_key ||= Rails.configuration.virustotal.api_key
  end

  def self.port
    @port ||= Rails.configuration.virustotal.port || 443
  end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def stringkey_params(conditions = {})
    Virustotal::Base.stringkey_params(conditions)
  end

  def self.new_request(path)
    raise 'Path required' unless path.present?
    raise 'Path must start with slash (/)' unless '/' == path[0]

    request = HTTPI::Request.new("https://#{host}:#{port}#{path}&apikey=#{api_key}")

    request.ssl = true
    request.auth.ssl.verify_mode = :peer

    request
  end

  def self.request(path:, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json

    request
  end

  def self.call_request(method, request)
    case method
      when :post
          HTTPI.post(request)
      else #:get
          HTTPI.get(request)
    end
  end

  def self.make_post_request(path:, body:)
      HTTPI.post(request(path: path, body: body))
  end

  def self.request_error_handling(response)
    case
      when 300 > response.code
        response
      when 404 == response.code
        body = JSON.parse(response.body)
        raise Virustotal::VirustotalNotFoundError, "HTTP response #{response.code} #{body['Error']}"
      else
        body = JSON.parse(response.body)
        raise Virustotal::VirustotalError, "HTTP response #{response.code} #{body['Error']}"
    end
  end

  def self.call_virustotal_request(method, path, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json

    response = request_error_handling(call_request(method, request))

    response_body = JSON.parse(response.body)
    response_body
  end

  def call_virustotal_request(method, path, body:)
    Virustotal::Base.call_virustotal_request(method, path, body: body)
  end

end