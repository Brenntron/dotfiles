require 'ipaddr'
require 'resolv'
class SbApi < ApplicationRecord

  API_RETRY_LIMIT = 5
  API_SOURCE = "www.senderbase.org"

  def self.sds_host
    Rails.configuration.sds.host
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
