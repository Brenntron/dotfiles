class FileReputationApi::Detection
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.amp_poke
  set_default_request_type :json
  #set_default_headers({})

  def self.create_action(sha256_hashes:, disposition:, detection_name: nil, ids: nil)
    byebug

  end
end
