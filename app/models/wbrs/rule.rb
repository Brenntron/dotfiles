class Wbrs::Rule
  include ActiveModel::Model         # need ActiveModel::Model
  include ActiveModel::Associations  # include this

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

  def self.post(path:, body:)
    HTTPI.post(request(path: path, body: body))
  end

  def self.get(categories: nil)
    response = post(path: '/v1/cat/rules/get', body: {"categories": categories })

    Rails.logger.debug(">>> Wbrs::Rule.get #{response.inspect}")
  end
end
