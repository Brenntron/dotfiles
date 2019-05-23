require 'ipaddr'
require 'resolv'
class SbApi < ApplicationRecord

  API_RETRY_LIMIT = 5
  API_SOURCE = "www.senderbase.org"

  def self.sds_host
    Rails.configuration.sds.host
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

  def self.build_sds_response(response, webcat_list, request_type)

    eb = {}
    eb["response"] = "Unavailable"
    eb["short_description"] = "-"
    eb["long_description"] = "-"
    begin
      score_plucked = pluck_score(response)
      eb["response"] = score_to_text(score_plucked, request_type)
      if score_plucked == "noscore"
        # "noscore" eventually becomes "Neutral", but later we want to
        # know cases which "Neutral" cases were because of "noscore"
        eb["show"] = "0"
      end
      cat_match = webcat_list[pluck_webcat_code(response)]
      eb["short_description"] = cat_match["name"]
      eb["long_description"] = cat_match["description"]
    rescue
    end
    eb.to_json
  end

  def self.sbrs_to_text(original_score)
    # Poor is -10 to -2.0
    # Neutral is -1.9 to 0.9
    # Neutral (score none)
    # Good is +1.0 to +10
    t = 'Neutral'
    begin
      score = original_score.to_f
      case
      when score >= 1         # Good is +1.0 to +10
        t = 'Good'
      when score > -2         # Neutral is -1.9 to 0.9
        t = 'Neutral'
      when score <= -2        # Poor is -10 to -2.0
        t = 'Poor'
      when score == 'noscore' # Neutral (score none)
        t = 'Neutral'
      else
        t = 'Neutral'
      end
    rescue
      t = 'Neutral'
    end
  end

  def self.score_to_text(original_score, score_type = "wbrs")
    txt = 'Unavailable'
    begin
      if score_type == "sbrs" or score_type == "ip"
        txt = sbrs_to_text(original_score)
      elsif score_type == "wbrs" or score_type == "url"
        txt = wbrs_to_text(original_score)
      end
    rescue
      txt = 'Unavailable'
    end
    txt
  end

  def self.pluck_webcat_code(response)
    JSON.parse(response.body)[0]["response"]["webcat"]["cat"].to_s
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

  def self.pluck_webcat_version(webcat_list)
    webcat_list["META_CATEGORIES_VERSION"]["current_version"].to_s
  end

  def self.remote_lookup_sds(params)
    hostname = "v2.sds.cisco.com"
    # query_string = "/score/wbrs;webcat/json?url=google.com"
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
        req_options = {
            use_ssl: uri.scheme == "https",
            cert: OpenSSL::X509::Certificate.new(ENV["SDS_CERT"].gsub("\\n", "\n")),
            key: OpenSSL::PKey::RSA.new(ENV["SDS_CERT"].gsub("\\n", "\n")),
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
      json_response = self.get_auth_key(Rails.configuration.sds.user,Rails.configuration.sds.pass, params["retried"])
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
end
