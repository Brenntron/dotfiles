class Beaker::Base
  include ActiveModel::Model

  def self.host
    @host ||= Rails.configuration.bls.host || 'localhost'
  end

  def self.port
    @port ||= Rails.configuration.bls.port || 80
  end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def stringkey_params(conditions = {})
    Beaker::Base.stringkey_params(conditions)
  end

  def self.new_request(path)
    raise 'Path required' unless path.present?
    raise 'Path must start with slash (/)' unless '/' == path[0]

    request = HTTPI::Request.new("https://#{host}:#{port}/v1#{path}")

    request.ssl = true
    request.auth.ssl.verify_mode = :none
    request
  end

  def self.request(path:, body:)
    request = new_request(path)

    request.headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer test"
    }
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
        body = response.body
        raise Beaker::BeakerNotFoundError, "HTTP response #{response.code} #{body['Error']}"
      else
        body = response.body
        raise Beaker::BeakerError, "HTTP response #{response.code} #{body['Error']}"
    end
  end

  def self.call_beaker_request(method, path, body, raw = false, content_type: 'application/json')
    request = new_request(path)

    # TODO: In production, a real Bearer token should go here, but so far, no one has
    # been able to specify where to find one. On lower environments, any string will work.
    request.headers = {'Content-Type' => content_type, 'Authorization' => 'Bearer test' }
    request.body = body.to_json

    response = request_error_handling(call_request(method, request))
    return response.body if raw == true
    JSON.parse(response.body)
  end

  def call_beaker_request(method, path, body:, content_type: 'application/json')
    Beaker::Base.call_beaker_request(method, path, body, false, content_type: content_type)
  end

end
