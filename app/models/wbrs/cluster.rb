class Wbrs::Cluster < Wbrs::Base

  SERVICE_STATUS_NAME = "RULEAPI:CLUSTER"

  def self.service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(test = nil, conditions: {})
    service_status_data = {}
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
      params = stringkey_params(conditions)

      response = call_json_request(:post, '/v1/clusters/get', body: params)

      if response.code >= 300
        (0..2).each do
          response = call_json_request(:post, '/v1/clusters/get', body: params)
          if response.code < 300
            break
          end
        end
      end

      if response.code >= 300
        service_status_data[:type] = "outage"
        service_status_data[:exception] = "/v1/clusters/get not loading or responding"
        service_status_data[:exception_details] = response.error rescue response.body

        service_status.log(service_status_data)
      else
        service_status_data[:type] = "working"
        service_status.log(service_status_data)
      end
      response_body = JSON.parse(response.body)
      response_body
    end

  end

  # @param [String] regex: Regular expression to be used to filter out clusters (optional)
  # @param [Integer] limit: Max number of records to return (optional) Default: 1000
  # @param [Integer] offset: Offset of the first record to return

  #
  def self.where(conditions = {})
    service_status_data = {}
    params = stringkey_params(conditions)

    response = post_request(path: '/v1/clusters/get', body: params)

    if response.code >= 300
      (0..2).each do
        response = call_json_request(:post, '/v1/clusters/get', body: params)
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/clusters/get not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)

    response_body

  end

  def self.retrieve(cluster_id, test = nil)
    service_status_data = {}
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

    if response.code >= 300
      (0..2).each do
        response = call_json_request(:get, "/v1/clusters/get/#{cluster_id}", body: '')
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/clusters/get/:id not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)

    response_body
  end

  def self.retrieve_many(cluster_ids)
    service_status_data = {}
    ids = URI.encode_www_form({ id: cluster_ids })
    response = call_json_request(:get, "/v1/clusters/get?#{ids}", body: '')

    if response.code >= 300
      (0..2).each do
        response = call_json_request(:get, "/v1/clusters/get?#{ids}", body: '')
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/clusters/get/:ids not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    JSON.parse(response.body)
  end

  #This is still a work in progress, need to get finalized version from UKR team
  # @param [Integer] cluster_id: The cluster(domain) to be categorized
  # @param [Array<Integer>] category_ids: List of up to 5 categories to apply to the cluster_id
  # @param [String] comment: comment to add to category rule
  # @param [String] user:  username of user committing categories to clusters
  def self.process(conditions = {}, test =  nil)
    service_status_data = {}
    if test.present?
      return {}
    end

    response = post_request(path: '/v1/clusters/process', body: conditions)

    if response.code >= 300
      (0..2).each do
        response = post_request(path: '/v1/clusters/process', body: conditions)
        if response.code < 300
          break
        end
      end
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/clusters/process"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end

    response_body = JSON.parse(response.body)
    response_body
  end
end
