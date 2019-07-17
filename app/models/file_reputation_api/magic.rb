# 69f3e339c070720906cf40499be79247dbb02758fbf08c72407f81645695c69e

class FileReputationApi::Magic
  include ActiveModel::Model
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.magic_api
  set_default_request_type :json
  #set_default_headers({})

  #attr_accessor :score, :disposition, :got, :score_tg, :samples_disp, :state, :name, :samples_name

  def self.run_analysis(hash)
    data = {
        "hash" => hash,
        "submitter" => 'auto-resolve'
    }
    call_request_parsed(:post, "/api/submit/whole_process", input: data)
  end

end
