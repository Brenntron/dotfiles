class FileReputationApi::Sandbox 
  include ApiRequester::ApiRequester

  set_api_requester_config Rails.configuration.file_reputation_sandbox
  set_default_request_type :json
  set_default_headers({})

  def self.amp_lookup(sha256)

    #endpoint = "/api/2/disposition"
    endpoint = "/ntu/1/disposition"
    query_string = {
        "hash" => sha256,
        "apikey" => api_key
    }
    begin
      response = JSON.parse(call_request(:get, endpoint, :request_type => :query_string, :input => query_string).body)
      data = {:success => true, :data => response}
    rescue
      data = {:success => false, :data => {}}
    end

    data
      
  end

  def self.sandbox_score(sha256)
    endpoint = "/api/2/report/latest"

    query_string = {
        "hash" => sha256,
        "apikey" => api_key
    }

    begin
      response = JSON.parse(call_request(:get, endpoint, :request_type => :query_string, :input => query_string).body)
      data = {:success => true, :data => response}
    rescue
      data = {:success => false, :data => {}}
    end

    data

  end  
end  
