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

  def self.sds_v3_host
    @sds_v3_host ||= Rails.configuration.sds.v3_host
  end

  def self.remote_call_sds_v3(sds_item, sds_type)
    self.remote_lookup_sds_v3(self.build_sds_v3_request(sds_item, sds_type))
  end

  def self.combo_call_sds_v3(uri, ip)
    self.remote_lookup_sds_v3(self.build_sds_v3_combo_request(uri, ip))
  end

  # Builds params for remote_lookup_sds_v3
  def self.build_sds_v3_request(sds_item, sds_type)
    uri_query                  = {}
    uri_query["hostname"]      = Sbrs::Base.sds_v3_host
    uri_query["query_string"]  = self.determine_sds_v3_uri(sds_type)
    uri_query["uri_item"]      = sds_item
    uri_query["sds_type"]      = sds_type
    uri_query
  end

  def self.build_sds_v3_combo_request(uri_item, ip_items)

    ip_params_string = ""
    if ip_items.size > 0
      ip_params_string = "&"
    end

    ip_params_string += ip_items.map {|ip| "ip=#{ip}"}.join("&")

    uri_query                  = {}
    uri_query["hostname"]      = Sbrs::Base.sds_v3_host
    uri_query["query_string"]  = '/score/single/json?url='+ uri_item + ip_params_string
    uri_query["sds_type"]      = "combo"
    uri_query
  end

  def self.port
    @port ||= Rails.configuration.sbrs.port || 80
  end

  def self.tls_mode
    @tls_mode ||= Rails.configuration.sbrs.verify_mode || 'no-tls'
  end

  def self.gssnegotiate?
    @gssnegotiate ||= false
  end

  def self.ca_cert_file
    @ca_cert_file ||= Rails.configuration.sds.ca_cert_file
  end

  def self.pkey_file
    @pkey_file ||= Rails.configuration.sds.pkey_file
  end

  def self.read_timeout
    @read_timeout ||= Rails.configuration.sds.read_timeout
  end
  def self.open_timeout
    @open_timeout ||= Rails.configuration.sds.open_timeout
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

  def self.determine_sds_v3_uri(sds_type)
    # Add more endpoints as needed
    case sds_type
    when 'webcat_labels'
      "/labels/aupc/json"
    when 'threatcat_labels'
      "/labels/thrt_cats/json"
    when 'wbrs'
      "/score/single/json?url="
    end
  end

  def self.build_sds_v3_response(parsed_body, webcat_list, threatcat_list)
    parsed_response = {}
    parsed_response['categories'] = []
    parsed_response['threat_categories'] = []
    parsed_response['threat_score'] = []

    begin
      categories = pluck_sds_v3_webcat_code(parsed_body)
      threat_categories = pluck_sds_v3_threat_category_codes(parsed_body)

      if categories.present?
        categories.each do |category|
          matched_category = webcat_list[category.to_s]
          parsed_response['categories'] << {short_description: matched_category['name'], long_description: matched_category['description']}
        end
      end

      if threat_categories.present?
        # Convert threat_category_ids to labels
        threat_categories.each do |threat_category|
          matched_threat_category = threatcat_list[threat_category.to_s]
          parsed_response['threat_categories'] << matched_threat_category['name']
        end
      end

      threat_score = pluck_sds_v3_threat_score(parsed_body)
      if threat_score == "noscore" or threat_score == ""
        parsed_response["show"] = "0"
      end
      # parsed_response['thrt_scor'] = threat_score     # RAW NUMBER, HELPFUL FOR DEV/DEBUG
      parsed_response['threat_score'] = [wbrs_to_new_threat_level(threat_score), wbrs_to_old_threat_level(threat_score)]

    rescue
    end

    parsed_response.to_json
  end

  def self.request_sds(path:, body:, type: nil)
    # adapted from TI/sb_api, then heavily modified
    query_string = path
    cert = File.open(ca_cert_file, 'r') do |file|
      file.read
    end
    pkey = File.open(pkey_file, 'r') do |file|
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
          verify_mode: OpenSSL::SSL::VERIFY_NONE,
          read_timeout: read_timeout,
          open_timeout: open_timeout
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


  def self.remote_lookup_sds_v3(params)
    hostname = "#{params["hostname"]}"
    query_string = "#{params["query_string"]}"
    request_type = "#{params["sds_type"]}"

    if request_type.blank? && query_string.match?('/score/single/json')
      request_type = 'wbrs'
    end

    first_char = query_string[0]
    query_string = '/' + query_string if first_char != '/'

    request_string = "https://" + hostname + query_string
    
    if request_type == 'wbrs' && params["uri_item"]
      request_string += params["uri_item"]
    end

    if request_string.present?
      uri = URI.parse(request_string)
      request = Net::HTTP::Get.new(uri)
      request["X-Client-ID"] = "talosweb"
      request["X-Product-ID"] = "talosintelligence"
      request["X-Device-ID"] = "talosweb"

      cert_string = File.open(ca_cert_file, 'r') do |file|
        file.read
      end
      pkey_string = File.open(pkey_file, 'r') do |file|
        file.read
      end

      cert = OpenSSL::X509::Certificate.new(cert_string.gsub("\\n", "\n"))
      key = OpenSSL::PKey::RSA.new(pkey_string.gsub("\\n", "\n"))

      req_options = {
          use_ssl: uri.scheme == "https",
          cert: cert,
          key: key,
          verify_mode: OpenSSL::SSL::VERIFY_NONE
      }

      begin
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        if response.code != "200"
          '{"response": "request failed"}'
        else
          if request_type == 'wbrs' || request_type == 'combo'
            sds_v3_response_parsed = JSON.parse(response.body)

            wbrs_response = {}
            wbrs_response["wbrs"] = {"score" => sds_v3_response_parsed["rsp"]["thrt_scor"].to_f}
            wbrs_response["wbrs-rulehits"] = sds_v3_response_parsed["rsp"]["thrt_rhts"]
            wbrs_response["proxy_uri"] = sds_v3_response_parsed["rsp"]["uri"] rescue ""
            wbrs_response["threat_cats"] = sds_v3_response_parsed["rsp"]["thrt_cats"] rescue nil

            # This is just some cleaning for backwards-compatibility with the v2 format
            if wbrs_response["wbrs-rulehits"] == nil
              wbrs_response["wbrs-rulehits"] = {}
            end

            wbrs_response
          elsif request_type == 'webcat_labels' || request_type == 'threatcat_labels'
            response.body
          end
        end
      rescue
        '{"response": "request failed"}'
      end
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
