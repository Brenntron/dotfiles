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
        'glob_volume'=>cluster['global_volume'].to_i || 0,
        'ctime'=>"Fri, 21 Sep 2018 12:53:40 GMT",
        'mtime'=>"Fri, 21 Sep 2018 12:53:40 GMT",
        'apac_volume'=>0,
        'emrg_volume'=>0,
        'eurp_volume'=>0,
        'japn_volume'=>0,
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

Given(/^the following ngfw clusters exist:$/) do |ngfw_clusters|
  ngfw_clusters.hashes.each do |ngfw_cluster|
    FactoryBot.create(:ngfw_cluster, domain: ngfw_cluster['domain'], traffic_hits: ngfw_cluster['traffic_hits'].to_i)
  end
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

Given(/^GuardRails verdicts API is stubbed to return success for domain "(.*?)"$/) do |domain|
  response_body = {}
  response_body[domain] = { color: Webcat::GuardRails::PASS }
  response = double('Net::HTTPResponse', code: 200, body: response_body.to_json)
  Webcat::GuardRails.stub(:verdict_for_entry).and_return(response)
end

Given(/^GuardRails verdicts API is stubbed to return failure for domain "(.*?)"$/) do |domain|
  response_body = {}
  response_body[domain] = { color: 'red' }
  response = double('Net::HTTPResponse', code: 200, body: response_body.to_json)
  Webcat::GuardRails.stub(:verdict_for_entry).and_return(response)
end

Given(/^the following cluster categorizations exist:$/) do |cluster_categorizations|
  cluster_categorizations.hashes.each do |cluster_categorization|
    FactoryBot.create(:cluster_categorization, cluster_categorization)
  end
end
