class Bast::Base
  include ApiRequester::ApiRequester

  INTEL_OPTION = 'ace'

  set_api_requester_config Rails.configuration.bast
  set_default_headers({ 'Token' => api_key })

  # usage:
  #  Bast::Base.create_task(['pravda.com.ua', 'cisco.com'])
  # response example:
  #   {"status"=>"success", "task_id"=>293}
  def self.create_task(domains)
    body = {
      'Urls'=> domains,
      'Intel'=> [INTEL_OPTION]
    }

    call_request_parsed(:post, '/api/create_task', request_type: :form_data, input: body)
  end

  # usage:
  #   Bast::Base.get_task_status(293)
  # response example:
  #   {"status"=>"Completed", "task_id"=>293}
  def self.get_task_status(task_id)
    call_request_parsed(:get, "/api/task_status/#{task_id}")
  end


  # usage:
  # Bast::Base.get_task_status(293)
  # response example:
    # {"cisco.com"=>{"import"=>true, "category"=>"comp", "umbrella_rank"=>434, "wbnp_rank"=>62, "alexa_rank"=>1570}, "pravda.com.ua"=>{"import"=>true, "category"=>"news", "umbrella_rank"=>65475, "wbnp_rank"=>41868, "alexa_rank"=>2783}}
  def self.get_task_result(task_id)
    call_request_parsed(:get, "api/download_json/#{task_id}")
  end
end

