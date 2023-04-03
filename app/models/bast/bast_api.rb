class Bast::BastApi < Bast::Base

  #Intel options
  # catscrubber
  # catoscope
  # urlfs2
  # webrepscore
  # top_1m
  # iprd


  def self.get_task_status(task_id)
    make_request(method: :get, path: "/api/task_status/#{task_id}")
  end

  def self.download_result(task_id)
    make_request(method: :get, path: "/api/download_result/#{task_id}")
  end

  def self.create_task(urls)
    bast_params = {
        "Urls" => urls,
        "Intel" => ['catoscope', 'top_1m'] #TODO: which intel options to use
    }
    make_request(method: :post, path: "/api/create_task", body: bast_params)
  end

end