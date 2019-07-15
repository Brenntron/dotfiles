class FileReputationApi::Sandbox
  include ApiRequester::ApiRequester

  set_api_requester_config Rails.configuration.file_reputation_sandbox
  set_default_request_type :query_string
  set_default_headers({})

  def self.type_based_api_key(api_key_type)
    Rails.configuration.file_reputation_sandbox.api_keys[api_key_type] ||
        raise("Missing #{api_key_type} sandbox API key")
  end

  def self.sandbox_score(sha256, api_key_type:)

    endpoint = "/api/2/disposition"
    #endpoint = "/ntu/1/disposition"
    query_string = {
        "hash" => sha256,
        "apikey" => type_based_api_key(api_key_type)
    }
    begin
      response = call_request_parsed(:get, endpoint, :input => query_string)
      data = {:success => true, :data => response["value"]}
    rescue
      data = {:success => false, :data => {}}
    end

    data
      
  end

  def self.sandbox_disposition(sha256)

    endpoint = "/ntu/1/disposition"
    query_string = {
        "hash" => sha256,
        "apikey" => type_based_api_key(FileReputationDispute::SANDBOX_KEY_AC_REFRESH)
    }
    begin
      response = call_request_parsed(:get, endpoint, :input => query_string)
      data = {:success => true, :data => response["entry"]["disposition"]}
    rescue
      data = {:success => false, :data => {}}
    end

    data
  end

  def self.report_data(sha256)

    endpoint = "/api/2/report"
    query_string = {
        "hash" => sha256,
        "apikey" => api_key,
        "runid" => '1'
    }
    begin
      response = call_request_parsed(:get, endpoint, :input => query_string)

      data = {:success => true, :file_size => response['dropped_files']['size'], :type => response['dropped_files']['type']}
    rescue
      data = {:success => false}
    end

    data
  end

  def self.sandbox_latest_report(sha256, api_key_type:)
    endpoint = "/api/2/report/latest"

    query_string = {
        "hash" => sha256,
        "apikey" => type_based_api_key(api_key_type)
    }

    begin
      response = call_request_parsed(:get, endpoint, :input => query_string)
      data = {:success => true, :data => response}
    rescue
      data = {:success => false, :data => {}}
    end

    data

  end

  def self.full_report(sha256, runid, api_key_type:)
    endpoint = "/api/2/report"

    query_string = {
        "hash" => sha256,
        "runid" => runid,
        "apikey" => type_based_api_key(api_key_type)
    }

    begin
      response = call_request_parsed(:get, endpoint, :input => query_string)
      data = {:success => true, :data => response}
    rescue
      data = {:success => false, :data => {}}
    end

    data
  end

  def self.full_report_html(sha256, runid)
    endpoint = "/api/2/report/html"

    query_string = {
        "hash" => sha256,
        "runid" => runid,
        "apikey" => type_based_api_key(FileReputationDispute::SANDBOX_KEY_AC_REFRESH)
    }

    begin
      response = call_request(:get, endpoint, :input => query_string)
      data = {:success => true, :data => response}
    rescue
      data = {:success => false, :data => {}}
    end

    data
  end

  def self.score(sha256_hash, api_key_type:)
    latest_report = FileReputationApi::Sandbox.sandbox_latest_report(sha256_hash, api_key_type: api_key_type)
    run_id = latest_report[:data]['runid']
    full_report = FileReputationApi::Sandbox.full_report(sha256_hash, run_id, api_key_type: api_key_type)
    full_report[:data]['score']
  end

  def self.run_sample(sha256_hash)
    endpoint = "/api/2/run/hash"

    query_string = {
        "hash" => sha256_hash,
        "apikey" => type_based_api_key(FileReputationDispute::SANDBOX_KEY_AC_REFRESH)
    }

    begin
      response = call_request(:post, endpoint, :input => query_string)
      data = {:success => true, :data => response}
    rescue
      data = {:success => false, :data => {}}
    end

    data


  end

  ########################################################
  # some example shas with possible history in sandbox
  #  7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069
  #  088d1d4ef6572aaf2563125c594345294b8f9d37dcd16cf4f719c77e6e0b50fd
  #  72395b2866d155e566566da4229cee1511d709e6c7d73811b89f20fd27a00f5f
  #  A88CA2557A76F29424C32B9D500FADA7C86A65A674643304D368B6602FC32A9C   <- has history
  #  0000000000000000000000000000000000000000000000000000000000000000
  #  e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  #  cdcdce071b22166ba25c016c498b6ebe6e04750a2d7500d0614a0b92dfc6c578
  #  9895988ade15c173b54749d12ffd098955e835daca25470970ae911ba200afce
  #  12a8043ee22d45f5d2c99ec34bff20cf21120614ba505e25f4b4e6ca5704a100
  #  3d5b3d793dd364e48230a936d4b7b8aa0e064ed92a9aba94fda841b12b22ee03
  #  2b02460613d888536b83ec9e658e33e98cb8d8d89eb811cf5528fed78cebd062
  #  42885df832c2d7e8e7fae192986a2d4f643ebeb1829ff605b9e8c7e9597a3e76
  #  35c760c9757a1c3448bb7e7c7859c4463757293a4e6acbc3b167feeae3bbbc09
end  