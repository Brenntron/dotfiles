class Sbrs::Base
  include ActiveModel::Model

  #TODO: all of this needs to be refactored and improved.  Finished up quickly because of deadline.

  def self.load_rules_matchup
    # a single call to the authority list of number==>rule data (used after SDS calls)

    begin
      JSON.parse(
          request_sds(path: '/labels/wbrs-rulehits/json', body: '').body
      )
    rescue Exception => e
      JSON.parse('{}')
    end
  end

  def self.rules_matchup
    @rules_matchup ||= self.load_rules_matchup
  end

  def self.sds_host
    @sds_host ||= Rails.configuration.sds.host
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

  # def self.sds_cert
  #   @sds_cert ||= ENV['SDS_CERT'] || ""
  # end

  def self.stringkey_params(conditions = {})
    conditions.inject({}) do |params, (key, value)|
      params[key.to_s] = value if value
      params
    end
  end

  def stringkey_params(conditions = {})
    Sbrs::Base.stringkey_params(conditions)
  end

  def self.determine_sds_uri(sds_type)
    if sds_type == "sbrs"
      "/score/sbrs/json?ip="
    else
      "/score/wbrs;wbrs-rulehits/json?url="
    end
  end

  def self.request_sds(path:, body:, type: nil)
    # adapted from TI/sb_api, then heavily modified
    query_string = path
    cert = File.open(Rails.configuration.sds.cert_file, 'r') do |file|
      file.read
    end
    pkey = File.open(Rails.configuration.sds.pkey_file, 'r') do |file|
      file.read
    end
    if /\/score\// =~ query_string ? true : false
      if type == 'wbrs'
        uri_item = "#{body['url']}"
      else
        uri_item = "#{body['ip']}"
      end

      request_string = "https://" + sds_host + query_string + uri_item
      uri = URI.parse(request_string)
      request = Net::HTTP::Get.new(uri)
      request["X-SDS-Categories-Version"] = "v8"     # <-- dude totally deal with this mess ::: SDS CATEGORY VERSION
      request["X-Client-ID"] = "talosweb"
      request["X-Product-ID"] = "talosintelligence"
      req_options = {
          use_ssl: uri.scheme == "https",
          cert: OpenSSL::X509::Certificate.new(cert),
          key: OpenSSL::PKey::RSA.new(pkey),
          # ca_file: Rails.configuration.sds.cert_file,
          verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
      begin
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        if response.code != "200"  #there was an issue
          '{"response": "request failed"}'
        else
          response # was: response.body per T/I source code
        end
      rescue
        '{"response": "request failed"}'
      end
    elsif /\/labels\// =~ query_string ? true : false
      request_string = "https://" + sds_host + query_string

      uri = URI.parse(request_string)
      request = Net::HTTP::Get.new(uri)
      request["X-Client-ID"] = "talosweb"
      request["X-Product-ID"] = "talosintelligence"
      req_options = {
          use_ssl: uri.scheme == "https",
          cert: OpenSSL::X509::Certificate.new(cert),
          key: OpenSSL::PKey::RSA.new(pkey),
          # ca_file: Rails.configuration.sds.cert_file,
          verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
      begin
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        if response.code != "200"  #there was an issue
          '{"response": "request failed"}'
        else
          response # was: response.body per T/I source code
        end
      rescue
        '{"response": "request failed"}'
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
