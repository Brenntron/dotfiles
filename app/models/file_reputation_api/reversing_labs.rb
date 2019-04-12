class FileReputationApi::ReversingLabs

  # TODO: Either open a ticket to make ApiRequester support HTTP basic auth OR come back here and
  # set up this stuff when it does.

  #       include ApiRequester::ApiRequester

  #       set_api_requester_config Rails.configuration.reversing_labs
  #       set_default_request_type :json
  #       set_default_headers "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}"

  def self.reversing_labs_url
    Rails.configuration.reversing_labs.url
  end

  def self.reversing_labs_username
    Rails.configuration.reversing_labs.username
  end

  def self.reversing_labs_password
    Rails.configuration.reversing_labs.password
  end

  def self.sha256_lookup(sha256)
    uri = URI(reversing_labs_url + "api/databrowser/rldata/query/sha256/#{sha256}?format=json")

    if Rails.cache.read(uri).blank?
      request = Net::HTTP::Get.new(uri)
      request.basic_auth reversing_labs_username, reversing_labs_password
      req_options = {
          use_ssl: uri.scheme == "https",
          verify_mode: OpenSSL::SSL::VERIFY_NONE
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if response.code != "200" #there was an issue
        {error: 'Data Currently Unavailable'}
      else
        begin
          response = JSON.parse(response.body)
          response
        rescue JSON::ParserError
          {error: 'Invalid Hash'}
        end
      end
    else
      Rails.cache.read(uri)
    end
  end

end
