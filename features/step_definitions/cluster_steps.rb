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
