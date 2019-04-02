class Wbrs::Base
  include ActiveModel::Model
  include ApiRequester::ApiRequester

  api_requester_config Rails.configuration.wbrs

  # TODO replace with new_request
  def self.request(path:, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json", "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}" }
    request.body = body.to_json

    request
  end

  # TODO replace with new_request
  def self.make_post_request(path:, body:)
    if gssnegotiate?
      HTTPI.post(request(path: path, body: body), :curb)
    else
      HTTPI.post(request(path: path, body: body))
    end
  end

  def self.call_json_request(method, path, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json", "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}" }

    request.body = body.to_json

    request_error_handling(call_request(method, request))
  end

  def call_json_request(method, path, body:)
    Wbrs::Base.call_json_request(method, path, body: body)
  end

  # TODO replace with call_json_request
  def self.post_request(path:, body:)
    request_error_handling(make_post_request(path: path, body: body))
  end
end
