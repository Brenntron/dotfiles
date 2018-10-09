class Wbrs::Cluster < Wbrs::Base
  FIELD_NAMES = %w{cluster_id domain apac_volume emrg_volume eurp_volume japn_volume glob_volume}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :category_id)

  def self.new_from_datum(datum)
    new(datum.slice(*FIELD_NAMES))
  end

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all
    response = call_json_request(:get, '/v1/clusters/get', body: '')
    response_body = JSON.parse(response.body)
    all = response_body['data'].map {|datum| new_from_datum(datum)}
    all
  end

  # @param [String] regex: Regular expression to be used to filter out clusters (optional)
  # @param [Integer] limit: Max number of records to return (optional) Default: 1000
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::Cluster>] Array of the results.
  def self.where(conditions = {})
    params = stringkey_params(conditions)

    response = post_request(path: '/v1/clusters/get', body: params)

    response_body = JSON.parse(response.body)

    results = response_body['data'].map {|datum| new_from_datum(datum)}
    results

  end

  #This is still a work in progress, need to get finalized version from UKR team
  # @param [Integer] cluster_id: The cluster(domain) to be categorized
  # @param [Array<Integer>] category_ids: List of up to 5 categories to apply to the cluster_id
  def self.process(conditions = {})
    params = stringkey_params(conditions)

    response = post_request(path: '/v1/clusters/process', body: params)

    response_body = JSON.parse(response.body)
    response_body
  end

end
