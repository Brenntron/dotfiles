class Wbrs::ManualWlbl < Wbrs::Base
  FIELD_NAMES = %w{id ctime list_type mtime threat_cats url username state}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}


  attr_accessor *FIELD_SYMS

  def self.new_from_attributes(attributes)
    new(attributes.slice(*FIELD_NAMES))
  end

  # Get all the manual WL/BL entries.
  # @return [Array<Wbrs::ThreatCategory>] Array of the results.
  def self.types
    response = get_request(path: '/v1/rep/wlbl/types/get', body: {})

    response_body = JSON.parse(response.body)
    response_body['data']
  end

  # @param [Integer] id the WL/BL
  # @return [Wbrs::Prefix] the WL/BL
  def self.find(id)
    response = get_request(path: "/v1/rep/wlbl/get/#{id}", body: {})

    response_body = JSON.parse(response.body)
    new_from_attributes(response_body)
  end

  # Get all the manual WL/BL entries.
  # @return [Array<Wbrs::ThreatCategory>] Array of the results.
  def self.where(conditions = {})
    params = stringkey_params(conditions)
    response = post_request(path: '/v1/rep/wlbl/get', body: params)

    response_body = JSON.parse(response.body)
    response_body['data'].map {|datum| new_from_attributes(datum)}
  end

  # Add a WL/BL on the backend
  # @param [Array<String>] url: URLs the WL/BL entries should be created for
  # @param [String] trgt_list: Target manual list type
  # @param [String] usr: User creating the WL/BL entries
  # @param [Array<String>] thrt_cats: List of up to five unique threat categories IDs
  # @param [String] note: User’s note
  # @return [Array<String>] warnings
  def self.add_from_params(params = {})
    response = post_request(path: '/v1/rep/wlbl/add', body: params)

    response_body = JSON.parse(response.body)
    response_body['Warnings']
  end

end
