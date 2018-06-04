class Wbrs::Base
  include ActiveModel::Model
  include ActiveModel::Associations

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def self.request(path:, body:)
    raise 'Path required' unless path.present?
    raise 'Path must start with slash (/)' unless '/' == path[0]
    request = HTTPI::Request.new("http://localhost:2944#{path}")
    # request.url = "http://localhost:2944#{path}"

    # request.auth.ssl.verify_mode = :peer
    # request.auth.ssl.ca_cert_file = ca_file #this will be nil for Heroku apps
    # request.auth.gssnegotiate
    # if request.auth.basic?
    #   request.auth.basic(@basic_auth[:user], @basic_auth[:password])
    # end

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json
    request
  end

  def self.get_request(path:, body:)
    response = HTTPI.get(request(path: path, body: body))
    unless 300 > response.code
      body = JSON.parse(response.body)
      raise "HTTP response #{response.code} #{body['Error']}"
    end
    response
  end

  def self.post_request(path:, body:)
    response = HTTPI.post(request(path: path, body: body))
    unless 300 > response.code
      body = JSON.parse(response.body)
      raise "HTTP response #{response.code} #{body['Error']}"
    end
    response
  end
end
