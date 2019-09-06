require 'ipaddr'
require 'resolv'
class SbApi < ApplicationRecord

  API_RETRY_LIMIT = 5
  API_SOURCE = "www.senderbase.org"

  def self.sds_host
    if Rails.env.production?
      ENV['SDS_HOSTNAME']
    else
      ENV['SDS_BETA_HOSTNAME']
    end
  end

  def self.sds_v3_host
    if Rails.env.production?
      ENV['SDS_V3_HOSTNAME']
    else
      ENV['SDS_V3_BETA_HOSTNAME']
    end
  end
  
  def self.get_auth_key(user,pass,retried = nil)

    if Rails.cache.read(:auth_token).present? and retried.blank?
      return Rails.cache.read(:auth_token)
    end

    uri = URI.parse("https://www.senderbase.org/api/v2/auth/")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.post(uri.path,"user_name="+user+"&user_password="+pass)
    json_package = JSON.parse(response.body)
    Rails.cache.write(:auth_token, json_package)

    json_package

  end

  def self.build_request(request_params, request_host, request_json)
    #figure out if query_entry is an Object (ActionController::Parameters) or a string
    if request_params["query_entry"].is_a?(String)
      build_request_from_string(request_params, request_host, request_json)
    else
      build_request_otherwise(request_params, request_host, request_json)
    end
  end

  def self.build_request_from_string(request_params, request_host, request_json)
    q_lookup = self.clean_request(request_params["query_entry"])
    query = "#{request_params["query"]}#{q_lookup}"
    header = self.authentication_header(request_json, query)
    query = URI.encode("#{request_params["query"]}#{q_lookup}")
    uri = URI.parse("https://#{request_host}#{query}?offset=#{request_params['offset']}&order=#{request_params['order']}")
    {uri: uri, header: header}
  end

  def self.build_request_otherwise(request_params, request_host, request_json)
    q_lookup = self.clean_request("#{request_params["query"]}")
    header = self.authentication_header(request_json, q_lookup)
    uri = URI.parse("https://#{request_host}#{q_lookup}")
    # add the parameters to the uri
    uri.query = URI.encode_www_form(request_params["query_entry"].to_hash)
    {uri: uri, header: header}
  end

  def self.clean_request(request_string)
    request_string = URI.decode(request_string).gsub(/(http|https)\:\/\//,'').gsub(/\+/,' ').gsub(/\ {2,}/, ' ').strip
    request_string = request_string + '/' unless request_string.match('\/$')
    request_string
  end

  def self.authentication_header(json_response, query)
    unless json_response['error'].present?
      secret = json_response['user_secret_key']
      public = json_response['user_public_key']
      date = Time.now.utc.strftime("%Y-%m-%d %H"":00")
      token_hash = Digest::SHA256.hexdigest secret+date
      digest = OpenSSL::Digest.new('sha512')
      hmac = OpenSSL::HMAC.hexdigest(digest, token_hash, query)
      header = public+":"+hmac
    end
  end

  def self.query_lookup(params, retries = nil)
    host = API_SOURCE
    #this line will pretty much only fire once...it's to bring retries variable into existence on the first failed attempt
    retries ||= 0

    begin
      json_response = self.get_auth_key(Rails.configuration.sds.username,Rails.configuration.sds.password, params["retried"])
      lookup_data = self.build_request(params, host, json_response)
      uri = lookup_data[:uri]
      header = lookup_data[:header]
      if Rails.cache.read(uri).blank?
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "#{header}" #add the request header
        req_options = {
            use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        #retry the look up at least once if it fails

        if response.code == "401" && (retries.present? && retries <= API_RETRY_LIMIT)

          params["retried"] = true
          #this is the actual line that will increment retries until it hits the max attempt as defined by API_RETRY_LIMIT
          retries += 1
          response = query_lookup(params, retries)
        else
          Rails.cache.write(uri, response.body)
          response.body
        end
      else
        Rails.cache.read(uri)
      end
    rescue
      '{}'
    end
  end

  def self.remote_lookup_sds(params)
    hostname = "#{params["hostname"]}"
    query_string = "#{params["query_string"]}"
    request_type = "#{params["sds_type"]}"
    if request_type == ""
      request_type = query_string.match?('/sbrs/') ? "sbrs" : "wbrs"
    end
    full_response = params["full_response"]
    request_string = ''
    first_char = query_string[0]
    query_string = '/' + query_string if first_char != '/'

    # three possible buckets for calls here
    # 1- call is looking for sbrs
    #   "/score/sbrs/json?ip="
    # 2- call is looking for wbrs including rule hits
    #   "/score/wbrs;wbrs-rulehits;webcat/json?url="
    #   IN THESE CASES, #3 must be called (and the version included) before calling 2
    # 3- call is looking for the webcat authority list (which also returns version)
    #   "/labels/webcat"

    request_string = "https://" + hostname + query_string
    if request_type == "webcat_labels"
      request_string += ""
    else
      if request_type == "wbrs"
        # before making a wbrs call, the webcat label lookup must be done
        # webcat label lookup will return a version number, which is then tacked onto the basic wbrs lookup,
        # and also, the labels will be needed to translate category names into text (wbrs returns codes)
        begin
          webcat_list = JSON.parse(self.remote_lookup_sds(self.build_sds_request('', 'webcat_labels', true)))
        rescue
          webcat_list = '{"response": "request failed"}'
        end
      end
      request_string += "#{params["uri_item"]}"
    end
    if request_string.present?
      uri = URI.parse(request_string)
      if Rails.cache.read(uri).blank? or Rails.env.development? or full_response
        request = Net::HTTP::Get.new(uri)
        request["X-Client-ID"] = "talosweb"
        request["X-Product-ID"] = "talosintelligence"
        if request_type == "wbrs"
          request["X-SDS-Categories-Version"] = "v" + self.pluck_webcat_version(webcat_list)
        end

        if Rails.env.production?
          cert = OpenSSL::X509::Certificate.new(ENV["SDS_CERT"].gsub("\\n", "\n"))
          key = OpenSSL::PKey::RSA.new(ENV["SDS_CERT"].gsub("\\n", "\n"))
        else
          cert = OpenSSL::X509::Certificate.new(ENV["SDS_CERT_BETA"].gsub("\\n", "\n"))
          key = OpenSSL::PKey::RSA.new(ENV["SDS_CERT_BETA"].gsub("\\n", "\n"))
        end

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

          if response.code != "200"  #there was an issue
            '{"response": "request failed"}'
          else
            if request_type == "webcat_labels"
              response.body # already been parsed?
            else
              if full_response
                response.body
              else
                sds_response = build_sds_response(response, webcat_list, request_type)
                Rails.cache.write(uri, sds_response)
                sds_response
              end
            end
          end
        rescue
          '{"response": "request failed"}'
        end
      else
        Rails.cache.read(uri)
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
      if Rails.cache.read(uri).blank? or Rails.env.development?
        request = Net::HTTP::Get.new(uri)
        request["X-Client-ID"] = "talosweb"
        request["X-Product-ID"] = "talosintelligence"
        request["X-Device-ID"] = "talosweb"

        if Rails.env.production?
          cert = OpenSSL::X509::Certificate.new(ENV["SDS_CERT"].gsub("\\n", "\n"))
          key = OpenSSL::PKey::RSA.new(ENV["SDS_CERT"].gsub("\\n", "\n"))
        else
          cert = OpenSSL::X509::Certificate.new(ENV["SDS_CERT_BETA"].gsub("\\n", "\n"))
          key = OpenSSL::PKey::RSA.new(ENV["SDS_CERT_BETA"].gsub("\\n", "\n"))
        end

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
            if request_type == 'wbrs'
              # Retrieve WebCat labels
              begin
                webcat_list = JSON.parse(self.remote_lookup_sds_v3(self.build_sds_v3_request(nil, 'webcat_labels')))
              rescue
                webcat_list = '{"response": "request failed"}'
              end

              # Retrieve ThreatCat labels
              begin
                threatcat_list = JSON.parse(self.remote_lookup_sds_v3(self.build_sds_v3_request(nil, 'threatcat_labels')))
              rescue
                threatcat_list = '{"response": "request failed"}'
              end

              sds_response = build_sds_v3_response(response, webcat_list, threatcat_list)
              Rails.cache.write(uri, sds_response)
              sds_response
            elsif request_type == 'webcat_labels' || request_type == 'threatcat_labels'
              response.body
            end
          end
        rescue
          '{"response": "request failed"}'
        end
      else
        Rails.cache.read(uri)
      end
    end
  end

  def self.determine_sds_uri(sds_type)
    # think about making this a case/switch?
    if sds_type == "sbrs"
      "/score/sbrs/json?ip="
    elsif sds_type == "webcat_labels"
      "/labels/webcat/json"
    else
      "/score/wbrs;wbrs-rulehits;webcat/json?url="
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

  def self.build_sds_request(sds_item, sds_type, full_response = false)
    uri_query                  = {}
    uri_query["hostname"]      = SbApi.sds_host
    uri_query["query_string"]  = self.determine_sds_uri(sds_type)
    uri_query["uri_item"]      = sds_item
    uri_query["sds_type"]      = sds_type
    uri_query["full_response"] = full_response
    uri_query
  end

  def self.build_sds_v3_request(sds_item, sds_type)
    uri_query                  = {}
    uri_query["hostname"]      = SbApi.sds_v3_host
    uri_query["query_string"]  = self.determine_sds_v3_uri(sds_type)
    uri_query["uri_item"]      = sds_item
    uri_query["sds_type"]      = sds_type
    uri_query
  end

  def self.build_sds_response(response, webcat_list, request_type)
    threat_level = {}
    threat_level["response"] = "Unavailable"
    # eb["short_description"] = "-"
    # eb["long_description"] = "-"

    begin
      score_plucked = pluck_score(response)
      threat_level["response"] = score_to_text(score_plucked, request_type)
      if score_plucked == "noscore"
        threat_level["show"] = "0"
      end

      # Disabling returning categories from SDSv2 call in ACE since it may not be used
      # cat_match = webcat_list[pluck_webcat_code(response)]
      # eb["short_description"] = cat_match["name"]
      # eb["long_description"] = cat_match["description"]
    rescue
    end
    threat_level.to_json
  end

  def self.build_sds_v3_response(response, webcat_list, threatcat_list)
    # Disabled returning categories since it may not be used in ACE

    parsed_response = {}
    # parsed_response['categories'] = []
    parsed_response['threat_categories'] = []

    # categories = pluck_sds_v3_webcat_code(response)
    threat_categories = pluck_sds_v3_threat_category_codes(response)

    # if categories.present?
    #   categories.each do |category|
    #     matched_category = webcat_list[category.to_s]
    #     parsed_response['categories'] << {short_description: matched_category['name'], long_description: matched_category['description']}
    #   end
    # end

    if threat_categories.present?
      # Convert threat_category_ids to labels
      threat_categories.each do |threat_category|
        matched_threat_category = threatcat_list[threat_category.to_s]
        parsed_response['threat_categories'] << matched_threat_category['name']
      end
    end

    parsed_response.to_json
  end

  def self.pluck_sds_v3_webcat_code(response)
    begin
      parsed_json = JSON.parse(response.body)
      parsed_json.dig('rsp','aupc').to_a
      webcat_code = JSON.parse(response.body)['rsp']['aupc'].to_a
    rescue
      webcat_code = []
    end

    webcat_code
  end

  def self.pluck_sds_v3_threat_category_codes(response)
    begin
      parsed_json = JSON.parse(response.body)
      threat_categories = parsed_json.dig('rsp','thrt_cats').to_a
    rescue
      threat_categories = []
    end

    threat_categories
  end

  def self.remote_call_sds(sds_item, sds_type, full_response = false)
    self.remote_lookup_sds(self.build_sds_request(sds_item, sds_type, full_response))
  end

  def self.remote_call_sds_v3(sds_item, sds_type)
    self.remote_lookup_sds_v3(self.build_sds_v3_request(sds_item, sds_type))
  end

  def self.score_to_text(original_score, score_type = "wbrs")
    txt = 'Unavailable'
    begin
      if score_type == "sbrs" or score_type == "ip"
        txt = sbrs_to_text(original_score)
      elsif score_type == "wbrs" or score_type == "url"
        # Returns an array with the new and old threat levels
        txt = [wbrs_to_new_threat_level(original_score), wbrs_to_old_threat_level(original_score)]
      end
    rescue
      txt = 'Unavailable'
    end
    txt
  end

  def self.wbrs_to_old_threat_level(original_score)
    score = original_score.to_f

    old_level = 'Unavailable'
    begin
      old_level = 'Neutral'
      case
      when score >= 3   #  10 to 3
        old_level = 'Good'
      when score > -6  # between 2.9 and -5.9, including "noscore"
        old_level = 'Neutral'
      else             # between -6 and -10
        old_level = 'Poor'
      end
    rescue
      old_level = 'Unavailable'
    end

    old_level
  end

  def self.wbrs_to_new_threat_level(original_score)
    score = original_score.to_f

    new_level = 'Unavailable'
    begin
      new_level = 'Neutral'
      case
      when score >= 6                 # 6.0 to 10.0
        new_level = 'Trusted'
      when score > 0                  # 5.9 to 0.1
        new_level = 'Favorable'
      when score >= -3                # 0 to -3.0
        new_level = 'Neutral'
      when score > -6                 # -3.1 to -5.9
        new_level = 'Questionable'
      else                            # -6.0 to -10.0
        new_level = 'Untrusted'
      end
    rescue
      new_level = 'Unavailable'
    end

    new_level
  end

  def self.pluck_webcat_version(webcat_list)
    webcat_list["META_CATEGORIES_VERSION"]["current_version"].to_s
  end

  def self.pluck_score(response)
    begin
      result = JSON.parse(response.body)
      if result[0]["response"]["wbrs"]
        result[0]["response"]["wbrs"]["score"].to_s
      else
        if result[0]["response"]["sbrs"]
          result[0]["response"]["sbrs"]["score"].to_s
        else
          "noscore_"
        end
      end
    rescue
      "noscore-"
    end
  end
end
