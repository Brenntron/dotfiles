class BugzillaRest::Base
  include ActiveModel::Model

  attr_reader :api_key, :token

  def initialize(api_key: nil, token: nil)
    @api_key = api_key
    @token = token
  end

  def host
    @host ||= Rails.configuration.bugzilla_host
  end

  def bugzilla_rest_error_msg(body)
    response_hash = JSON.parse(body)
    response_hash['message']
  rescue
    nil
  end

  def handle_errors(response)
    code = response.code
    msg = bugzilla_rest_error_msg(response.body)
    case
    when 401 == code
      raise BugzillaRest::AuthenticationError.new("Bugzilla REST Authentication Error.  #{msg}", code: code)
    when 300 >= code
      raise BugzillaRest::BaseError("Error using Bugzilla REST.  #{msg}", code: code)
    end
  end

  def post(path, body)

    # request = HTTPI::Request.new("https://fmd-bugzil-01tst.vrt.sourcefire.com/rest/bug")
    auth_query =
        if @api_key.present?
          "Bugzilla_api_key=#{@api_key}"
        else
          "Bugzilla_token=#{@token}"
        end
    request = HTTPI::Request.new("https://#{host}#{path}?#{auth_query}")

    request.ssl = true
    request.auth.ssl.verify_mode = :peer

    request.headers =
        {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            # 'Authorization' => "Bearer #{Rails.configuration.wbrs.auth_token}"
        }
    # if @api_key.present?
    #   request.headers['X-Bugzilla-API-Key'] = @api_key
    # else
    #   request.headers['X-Bugzilla-Token'] = @token
    # end


    request.body = body

    response = HTTPI.post(request)

    # raise response.body unless 300 > response.code
    handle_errors(response)

    response.body
  end
end
