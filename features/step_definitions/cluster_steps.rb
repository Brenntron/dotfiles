Given(/^Beaker Verdicts is stubbed with some response$/) do
  response = [
    {'request'=>{'url'=>'44.233.111.149'}, 'response'=>{'thrt'=>{'scor'=>-3.0, 'rhts'=>[72], 'thrt_vers'=>3}}},
    {'request'=>{'url'=>'144.121.168.175'}, 'response'=>{'thrt'=>{'scor'=>-3.0, 'rhts'=>[72], 'thrt_vers'=>3}}},
    {'request'=>{'url'=>'144.121.168.176'}, 'response'=>{'thrt'=>{'scor'=>-3.0, 'rhts'=>[72], 'thrt_vers'=>3}}},
    {'request'=>{'url'=>'144.121.168.177'}, 'response'=>{'thrt'=>{'scor'=>-3.0, 'rhts'=>[72], 'thrt_vers'=>3}}}
  ]
  Beaker::Verdicts.stub(:verdicts).and_return(response)
end

Given(/^WBRS Category is stubbed with some response$/) do
  response = [6]
  Wbrs::Category.stub(:get_category_ids).and_return(response)
end

Given(/^WBRS Cluster processing is stubbed with some response$/) do
  Wbrs::Cluster.stub(:process).and_return(true)
end

Given(/^WBRS TopUrl is stubbed with some response$/) do
  response = Wbrs::TopUrl.new_from_datum(
    url: 'example.com',
    is_important: true)
  Wbrs::TopUrl.stub(:check_urls).and_return(response)
end

Given(/^WBRS Cluster returns the following stubbed clusters:$/) do |clusters|
  response_data = []
  clusters.hashes.each do |cluster|
    response_data.push(
      {
        'cluster_id'=>cluster["id"],
        'domain'=>cluster["domain"],
        'ctime'=>"Fri, 21 Sep 2018 12:53:40 GMT",
        'mtime'=>"Fri, 21 Sep 2018 12:53:40 GMT",
        'apac_volume'=>0,
        'emrg_volume'=>0,
        'eurp_volume'=>0,
        'japn_volume'=>0,
        'glob_volume'=>7637758,
        'cluster_size'=>2
      }
    )
  end
  response = {
    'meta' => {"limit"=>1000, "rows_found"=>15161},
    'data' => response_data
  }

  Wbrs::Cluster.stub(:all).and_return(response)
  Wbrs::Cluster.stub(:where).and_return(response)
end

Given(/^the following cluster assignments exists:$/) do |cluster_assignments|
  cluster_assignments.hashes.each do |cluster_assignment|
    FactoryBot.create(:cluster_assignment, cluster_assignment)
  end
end

Given(/^WBRS TopUrl API call is stubbed with:$/) do |top_urls|
  response = []
  top_urls.hashes.each do |top_url|
    response.push(Wbrs::TopUrl.new_from_datum(
      url: top_url["url"],
      is_important: top_url["is_important"] == 'true'
    ))
  end
  Wbrs::TopUrl.stub(:check_urls).and_return(response)
end
