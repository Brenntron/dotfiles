class Webcat::Ncmec
  include ActiveModel::Model

  def self.host
    if Rails.env == "production"
      @host ||= "report.cybertip.org"
    else
      @host ||= "exttest.cybertip.org"
    end

  end

  def self.port
    @port ||= 443
  end

  def self.verify_mode
    @verify_mode ||= "verify-none"
  end

  def self.gssnegotiate?
    @gssnegotiate ||= nil
  end

  def self.read_timeout
    @read_timeout ||= 1800
  end
  def self.open_timeout
    @open_timeout ||= 1800
  end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def stringkey_params(conditions = {})
    RepApi::Base.stringkey_params(conditions)
  end

  def self.build_request_body(input)
    case input
      when Array
        string_array = input.map do |element|
          case
            when element.kind_of?(Array) && 1 == element.count
              element.first.to_s
            when element.kind_of?(Array) && 2 == element.count
              "#{element[0]}=#{element[1]}"
            else
              element.to_s
          end
        end
        string_array.join('&')
      else #when String
        input
    end
  end

  def build_request_body(input)
    RepApi::Base.build_request_body(input)
  end

  def self.new_request(path)
    raise 'Path required' unless path.present?
    raise 'Path must start with slash (/)' unless '/' == path[0]

    protocol = 'https'

    url = "#{protocol}://#{host}:#{port}#{path}"
    request = HTTPI::Request.new(url)
    #request.auth.basic(Rails.configuration.iwf_config.username, Rails.configuration.iwf_config.password)
    request.auth.basic("CiscoSystemsInc", "Mw4+Cq2@Fq9%")
    request.read_timeout = read_timeout
    request.open_timeout = open_timeout

    #case verify_mode
    #  when 'verify-peer'
    #    request.ssl = true
    #    request.auth.ssl.verify_mode = :peer
    #    request.auth.ssl.ca_cert_file = ca_cert_file #this will be nil for Heroku apps
    #    request.auth.ssl.ssl_version = :TLSv1_2
    #  when 'verify-none'
    #    request.ssl = true
    #    request.auth.ssl.verify_mode = :none
    #    request.auth.ssl.ssl_version = :TLSv1_2
    #  else #no-tls
    #    request.ssl = false
    #end

    #if gssnegotiate?
    #  request.auth.gssnegotiate
    #end

    request
  end

  def self.call_request(method, request)

    case method
      when :post
        binding.pry
        HTTPI.post(request)

      else #:get
        if gssnegotiate?
          HTTPI.get(request, :curb)
        else
          HTTPI.get(request)
        end
    end
  end

  def self.request_error_handling(response)

    data = nil

    if response.code > 204
      raise RepApi::RepApiError, "HTTP code: #{response.code}"
    end

    return response

  end


  def self.call_xml_request(body, path)
    request = new_request(path)
    method = :post

    request.headers['Content-Type'] = "text/xml; charset=utf-8"
    request.body = body

    request_error_handling(call_request(method, request))
  end

end
