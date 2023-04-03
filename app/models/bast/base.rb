class Bast::Base
  def self.host
    @host ||= Rails.configuration.bast.host
  end

  def self.token
    @token ||= Rails.configuration.bast.token
  end

  def self.headers
    {
        'Token' => token
    }
  end

  def self.make_request(method:, path:, body: nil)
    request = new_request(path)
    request.query = body

    case method
    when :post
      response = HTTPI.post(request)
    else
      response = HTTPI.get(request)
    end

    if response.code != 200
      request_error_handling(response)
    else
      JSON.parse(response.body)
    end
  end

  def self.new_request(path)
    raise 'Path required' unless path.present?
    raise 'Path must start with slash (/)' unless '/' == path[0]

    request = HTTPI::Request.new("http://#{host}#{path}")

    request.read_timeout = Rails.configuration.api_master_timeout
    request.open_timeout = Rails.configuration.api_master_timeout


    request.ssl = true
    request.auth.ssl.verify_mode = :none

    request.headers = headers

    request
  end

  def self.request_error_handling(response)
    case
    when 300 > response.code
      body = JSON.parse(response.body)
      raise Bast::BastError, "Unexpected Bast response, check request parameters" unless body.kind_of?(Hash)
    else
      body = JSON.parse(response.body)
      raise Bast::BastError, "HTTP response #{response.code} #{body['error']}"
    end
  end

end