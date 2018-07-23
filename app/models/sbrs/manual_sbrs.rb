class Sbrs::ManualSbrs < Sbrs::Base
  FIELD_NAMES = %w{id ctime list_type mtime threat_cats url username state}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}


  attr_accessor *FIELD_SYMS

  def self.new_from_attributes(attributes)
    new(attributes.slice(*FIELD_NAMES))
  end

  # Get all the manual SBRS/SDS entries.
  #   >> This has no analogy to SBRS/SDS, so leaving as a stub.
  def self.types
  end

  # @param [Integer] id the WL/BL
  # @return [Wbrs::Prefix] the WL/BL
  def self.find(id)
    response = call_json_request(:get, "/v1/rep/sbrs/get/#{id}", body: {})

    response_body = JSON.parse(response.body)
    new_from_attributes(response_body)
  end

  def self.load_from_prefetch(data)
    data = JSON.parse(data)
    data['data'].map {|datum| new_from_attributes(datum)}
  end

  def self.where(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    binding.pry
    response = request_sds(path: '/score/sbrs/json?ip=', body: params)
    binding.pry
    return response.body if raw == true
    response_body = JSON.parse(response.body)[0]
  end

  # Add a WL/BL on the backend
  def self.add_from_params(entries, wlbl_params)
  end

  def self.edit_from_params(entries, wlbl_params)
  end

  def self.drop_from_params(entries, wlbl_params)
  end

  # Add a WL/BL on the backend
  def self.adjust_from_params(params = {}, username:)
  end
end
