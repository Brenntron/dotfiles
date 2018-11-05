class BugzillaRest::Base
  include ActiveModel::Model

  attr_reader :api_key, :token

  def initialize(api_key: nil, token: nil)
    @api_key = api_key
    @token = token
  end

  def indifferent(attrs)
    attrs.inject(ActiveSupport::HashWithIndifferentAccess.new) do |hash, (key, value)|
      hash[key.to_s] = value
      hash
    end
  end

  def compact(attrs)
    attrs.reject { |key, value| value.nil? }
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
    when 300 <= code
      raise BugzillaRest::BaseError.new("Error using Bugzilla REST.  #{msg}", code: code)
    end
  end

  def call(method, path, body: '', query: {}, send_auth: true)
    query_data = query.clone

    case
    when !send_auth
      #do nothing
    when @api_key.present?
      query_data['Bugzilla_api_key'] = @api_key
    when @token.present?
      query_data['Bugzilla_token'] = @token
    end

    query_str = query_data.map { |key, value| "#{CGI.escape(key.to_s)}=#{CGI.escape(value)}" }.join('&')
    request = HTTPI::Request.new("https://#{host}#{path}?#{query_str}")

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

    response = HTTPI.send(method, request)

    # raise response.body unless 300 > response.code
    handle_errors(response)

    response.body
  end
end
