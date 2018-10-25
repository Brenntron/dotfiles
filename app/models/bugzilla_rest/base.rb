class BugzillaRest::Base

  def initialize(api_key:, token:)
    @api_key = api_key
    @token = token
  end

  def host
    @host ||= Rails.configuration.bugzilla_host
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

    raise response.body unless 300 > response.code

    response.body
  end
end
