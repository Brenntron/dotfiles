class K2::Base
  include ApiRequester::ApiRequester

  Response = Struct.new(:body, :error, :code)


  set_api_requester_config Rails.configuration.k2
  set_default_request_type :json

  def self.request
    request = HTTPI::Request.new()
    request.headers = {
      "Authorization" => "Bearer 1.0 #{Rails.configuration.k2.token}",
      'Content-type'  => "application/json"
    }
    request.auth.ssl.verify_mode = :none
    request
  end


  def self.request_error_handling(response)
    if response.error?
      handle_error_response(response)
    else
      parsed_response = Response.new
      parsed_response.body = JSON.parse(response.body)
      parsed_response.code = response.code
      parsed_response
    end
  end

  def self.handle_error_response(response = nil)
    return_response = Response.new
    error_message = 'Coud not fetch data from K2 API'
    return_response.code = response&.code
    error_message = response ? "HTTP response #{response&.code}. #{error_message}" : error_message
    Rails.logger.error(error_message)
    return_response.error = error_message
    return_response
  end
end
