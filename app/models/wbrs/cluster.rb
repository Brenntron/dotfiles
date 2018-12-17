class Wbrs::Cluster < Wbrs::Base

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(test = nil)
    if test.present?
      return [
          {
              "cluster_id": 7331,
              "domain": "googletest.com",
              "ctime": "Fri, 21 Sep 2018 12:53:40 GMT",
              "mtime": "Fri, 21 Sep 2018 12:53:40 GMT",
              "apac_volume": 0,
              "emrg_volume": 0,
              "eurp_volume": 0,
              "japn_volume": 0,
              "glob_volume": 7637758,
              "cluster_size": 2
          }
      ]

    else
      params = stringkey_params({})
      response = call_json_request(:post, '/v1/clusters/get', body: params)
      response_body = JSON.parse(response.body)
      response_body
    end

  end

  # @param [String] regex: Regular expression to be used to filter out clusters (optional)
  # @param [Integer] limit: Max number of records to return (optional) Default: 1000
  # @param [Integer] offset: Offset of the first record to return

  #
  def self.where(conditions = {})
    params = stringkey_params(conditions)

    response = post_request(path: '/v1/clusters/get', body: params)

    response_body = JSON.parse(response.body)

    response_body

  end

  def self.retrieve(cluster_id, test = nil)

    if test.present?
      return [
          {
              "apac_region_volume": 10,
              "emrg_region_volume": 20,
              "eurp_region_volume": 30,
              "glob_volume": 5,
              "japn_region_volume": 40,
              "na_region_volume": 50,
              "url": "http://www.googletest.com/url/1",
              "wbrs_score": 3.8
          },
          {
              "apac_region_volume": 10,
              "emrg_region_volume": 20,
              "eurp_region_volume": 30,
              "glob_volume": 3,
              "japn_region_volume": 40,
              "na_region_volume": 50,
              "url": "http://www.googletest.com/url/2",
              "wbrs_score": -3
          }
      ]

    end

    response = call_json_request(:get, "/v1/clusters/get/#{cluster_id}", body: '')
    response_body = JSON.parse(response.body)

    response_body
  end

  #This is still a work in progress, need to get finalized version from UKR team
  # @param [Integer] cluster_id: The cluster(domain) to be categorized
  # @param [Array<Integer>] category_ids: List of up to 5 categories to apply to the cluster_id
  # @param [String] comment: comment to add to category rule
  # @param [String] user:  username of user committing categories to clusters
  def self.process(conditions = {}, test =  nil)
    if test.present?
      return {}
    end
    params = stringkey_params(conditions)

    response = post_request(path: '/v1/clusters/process', body: params)

    response_body = JSON.parse(response.body)
    response_body
  end

end