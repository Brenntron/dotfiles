class Sbrs::Base
  include ActiveModel::Model

  def self.sds_host
    @sds_host ||= ENV['SDS_HOSTNAME']
  end

  def self.port
    @port ||= Rails.configuration.sbrs.port || 80
  end

  def self.tls_mode
    @tls_mode ||= Rails.configuration.sbrs.tls_mode || 'no-tls'
  end

  def self.gssnegotiate?
    @gssnegotiate ||= Rails.configuration.sbrs.gssnegotiate
  end

  def self.sds_cert
    @sds_cert ||= ENV['SDS_CERT'] || ""
  end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def stringkey_params(conditions = {})
    Sbrs::Base.stringkey_params(conditions)
  end

  def self.new_request(params)
    # adapted from TI/sb_api
    query_string = "#{params["query_string"]}"
    request_string = ''
    #first_char = query_string[0]
    #query_string = '/' + query_string if first_char != '/'
    webcat_flag = false
    if /\/score\// =~ query_string ? true : false
      uri_item = "#{params["uri_item"]}"
      request_string = "https://" + sds_host + query_string + uri_item
    elsif /\/labels\// =~ query_string ? true : false
      request_string = "https://" + sds_host + query_string
      webcat_flag = /\/labels\/webcat\// =~ query_string ? true : false
    end
    if request_string.present?
      uri = URI.parse(request_string)
      request = Net::HTTP::Get.new(uri)
      request["X-Client-ID"] = "talosweb"
      request["X-Product-ID"] = "talosintelligence"
      req_options = {
          use_ssl: uri.scheme == "https",
          cert: OpenSSL::X509::Certificate.new(sds_cert.gsub("\\n", "\n")),
          key: OpenSSL::PKey::RSA.new(sds_cert.gsub("\\n", "\n")),
          verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
      begin
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        if response.code != "200"  #there was an issue
          '{"response": "request failed"}'
        else
          if webcat_flag
            simple_hash = {}
            full_data = JSON.parse(response.body)
            full_data.keys.each do |k,v|
              if k.to_i > 0
                simple_hash[k] = full_data[k]["name"]
              end
            end
            simple_hash.to_json
          else
            response.body
          end
          if webcat_flag
            simple_hash = {}
            full_data = JSON.parse(response.body)
            full_data.keys.each do |k,v|
              if k.to_i > 0
                simple_hash[k] = full_data[k]["name"]
              end
            end
            simple_hash.to_json
          else
            response.body
          end
        end
      rescue
        '{"response": "request failed"}'
      end
    else
      '{"response": "no query_string clause for [' + query_string + ']"}'
    end
  end

  def self.call_sds(call_item = '', call_type = 'sbrs')
    params = {}
    if call_type == "sbrs"
      params["query_string"] = "/score/sbrs/json?ip="
      params["uri_item"] = call_item
    else
      params["query_string"] = "/score/wbrs;wbrs-rulehits/json?url="
      params["uri_item"] = call_item
    end
    new_request(params) unless params == {}
  end

  # TODO replace with new_request
  def self.request(path:, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json

    request
  end

  def self.call_request(method, request)
    case method
      when :post
        if gssnegotiate?
          HTTPI.post(request, :curb)
        else
          HTTPI.post(request)
        end
      else #:get
        if gssnegotiate?
          HTTPI.get(request, :curb)
        else
          HTTPI.get(request)
        end
    end
  end

  # TODO replace with new_request
  def self.make_post_request(path:, body:)
    if gssnegotiate?
      HTTPI.post(request(path: path, body: body), :curb)
    else
      HTTPI.post(request(path: path, body: body))
    end
  end

  def self.request_error_handling(response)
    case
      when 300 > response.code
        response
      when 404 == response.code
        body = JSON.parse(response.body)
        raise Sbrs::SbrsNotFoundError, "HTTP response #{response.code} #{body['Error']}"
      else
        body = JSON.parse(response.body)
        raise Sbrs::SbrsError, "HTTP response #{response.code} #{body['Error']}"
    end
  end

  def self.call_sbrs_request(method, path, body, raw = false)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
    request.body = body.to_json

    response = request_error_handling(call_request(method, request))
    # transform the response body into valid JSON, from the YAML provided by the API
    response_body = response.body.gsub("\n---\n",",")
    response_body = response_body.gsub("---\n", "")
    response_body = response_body.prepend("[").concat("]")
    return response_body if raw == true
    response_body = JSON.parse(response_body)
  end

  def call_sbrs_request(method, path, body:)
    Sbrs::Base.call_sbrs_request(method, path, body: body)
  end

end
