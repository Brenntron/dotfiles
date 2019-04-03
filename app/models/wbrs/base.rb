class Wbrs::Base
  include ActiveModel::Model
  include ApiRequester::ApiRequester

  set_api_requester_config Rails.configuration.wbrs
  set_default_request_type :json
  set_default_headers "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}"

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

  # TODO replace with call_json_request
  def self.post_request(path:, body:)
    request_error_handling(make_post_request(path: path, body: body))
  end
end
