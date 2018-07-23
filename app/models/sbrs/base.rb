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
    @gssnegotiate ||= false
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

  def self.request_sds(path:, body:)
    # adapted from TI/sb_api, then heavily modified
    query_string = path
    if /\/score\// =~ query_string ? true : false
      uri_item = "#{body["ip"]}"
      request_string = "https://" + sds_host + query_string + uri_item
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
          '{"response": "request failed[1]"}'
        else
          response # was: response.body per T/I source code
        end
      rescue
        '{"response": "request failed[2]"}'
      end
    else
      '{"response": "no query_string clause for [' + query_string + ']"}'
    end
  end

  def self.new_request(call_item = '', call_type = 'sbrs')
    params["query_string"] = "/score/sbrs/json?ip="
    params["uri_item"] = call_item
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
        raise Wbrs::WbrsNotFoundError, "HTTP response #{response.code} #{body['Error']}"
      else
        body = JSON.parse(response.body)
        raise Wbrs::WbrsError, "HTTP response #{response.code} #{body['Error']}"
    end
  end

  def self.call_json_request(method, path, body:)
    request = new_request(path)

    request.headers = {"Content-Type" => "application/json" }
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
