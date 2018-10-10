class Sbrs::GetSbrs < Sbrs::Base

  #TODO: all of this needs to be refactored and improved.  Finished up quickly because of deadline.

  API_RETRY_LIMIT = 5
  API_SOURCE = "www.senderbase.org"

  def self.load_from_prefetch(data)
    response_body = JSON.parse(data)
    response_body
  end

  def self.all
    call_sbrs_request(:get, "/v1/rules", body: {})
  end

  def self.by_domain(name, raw = false)
    call_sbrs_request(:get, "/v1/domain/#{name}", {}, raw )
  end

  def self.by_mnemonic(name, raw = false)
    call_sbrs_request(:get, "/v1/rules/#{name}", {}, raw)
  end

  def self.by_ip4(name, raw = false)
    call_sbrs_request(:get, "/v1/ip/#{name}", {}, raw)
  end

  def self.system_stats
    call_sbrs_request(:get, "/v1/status", body: {})
  end


  def self.get_sbrs_rules_for_ip(ip)
    response = query_lookup(build_sbapi_request(ip))
    parse_ip_rules(JSON.parse(response))
  end


  def self.parse_ip_rules(rep_data)
    ip_rules = []
    rep_data.fetch('blacklists', []).each do |blacklist|
      blacklist.each do |list_item|
        if list_item and list_item["rules"]
          # adding [0] since the rules are doubly encoded ie [["Cbl", "Spam source"]]
          list_item["rules"][0].to_a.each do |rule|
            ip_rules.append(rule)
          end
        end
      end
    end
    ip_rules
  end



  def self.clean_request(request_string)
    request_string = URI.decode(request_string).gsub(/(http|https)\:\/\//,'').gsub(/\+/,' ').gsub(/\ {2,}/, ' ').strip
    request_string = request_string + '/' unless request_string.match('\/$')
    request_string
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

  def self.build_request(request_params, request_host, request_json)
    #figure out if query_entry is an Object (ActionController::Parameters) or a string
    if request_params["query_entry"].is_a?(String)
      build_request_from_string(request_params, request_host, request_json)
    else
      build_request_otherwise(request_params, request_host, request_json)
    end
  end






  def self.query_lookup(params, retries = nil)
    host = API_SOURCE
    #this line will pretty much only fire once...it's to bring retries variable into existence on the first failed attempt
    retries ||= 0

    begin
      json_response = self.get_auth_key(ENV['SENDERBASE_USER'],ENV['SENDERBASE_PASS'], params["retried"])
      lookup_data = self.build_request(params, host, json_response)
      uri = lookup_data[:uri]
      header = lookup_data[:header]

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
        response.body
      end

    rescue
      '{}'
    end
  end

  #Just as a reference for possible future refactoring
  #Right now auth token caching is reactive....as in...it will keep trying to use
  #the cached token until there has been an http error indicating it has expired
  #in which case 'retried' will no longer be #blank? and it will skip reading from cache
  #and move to the code that sends the fetch auth token from senderbase api.
  #This isn't perfect, but it works for now.  If somebody wanted to come in and do some
  #general refactoring, and decided that this should be proactive instead:
  #the auth_token json package has some keys that you can work with, as it defines
  #the creation time and expiration time in unix epoch seconds.
  #the keys are:
  #"creation_time"
  #"expire_time"
  #example values might be:
  #"creation_time" = 1500052848    (which is July 14th, 2017 1:20pm roughly)
  #"expire_Time" = 1500056448     (3600 seconds/1 hour later at July 14th, 2017 2:20pm roughly)
  #so to proactively guess whether or not your auth token is expired you might do something
  #like:
  # If Rails.cache.read(:auth_token)["expire_time"] < Time.now.to_i (to_i converts the current time
  # to Unix epoch seconds)
  # Then skip and run he senderbase api call
  # at the time of this comment, there are a few obstacles that would make going this route
  # rather tricky in testing and development.
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

  def self.build_sbapi_request(item, query_string = "/api/v2/details/ip/")
    ip_query = {}
    ip_query["query"] = query_string
    ip_query["query_entry"] = item
    ip_query
  end


  def parse_ip_rules(rep_data)
    ip_rules = []
    rep_data["blacklists"].each do |blacklist|
      # this looks fugly
      for i in (0..blacklist.count)
        if blacklist[i] and blacklist[i]["rules"]
          # adding [0] since the rules are doubly encoded ie [["Cbl", "Spam source"]]
          blacklist[i]["rules"][0].to_a.each do |rule|
            ip_rules.append(rule)
            @total_rules.append(rule.downcase)
          end
        end
      end
    end
    ip_rules
  end



end
