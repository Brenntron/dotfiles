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

  def self.parse_sbrs(sbrs_response)
    JSON.parse(sbrs_response.body)[0]["response"]
  end

  def self.parse_wbrs(wbrs_response)
    wbrs_return = {}.merge(JSON.parse(wbrs_response.body)[0]["response"])
    #wbrs_rules = wbrs_return["wbrs-rulehits"]
    #wbrs_rules = rules_matchup
    #binding.pry
    wbrs_return["wbrs-rulehits"] = ["what","the","hell"]
    wbrs_return["wbrs-rulehits"] = Sbrs::Base.rules_matchup
    wbrs_return
  end

  def self.call_sbrs(params)
    parse_sbrs(request_sds(path: '/score/sbrs/json?ip=', body: params))
  end

  def self.call_wbrs(params)
    parse_wbrs(request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params))
  end

  def self.where(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    {}.merge(call_sbrs(params)).merge(call_wbrs(params))
    # this should return {"sbrs": {"score": "<score>"}}
    # where <score> is either between -10 and 10 (inclusive)
    # or noscore
  end

  def self.whorks(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    response = {}
    binding.pry
    rs = request_sds(path: '/score/sbrs/json?ip=', body: params)
    rs = JSON.parse(rs.body)[0]["response"]
    binding.pry
    response = response.merge(rs)
    binding.pry
    rw = request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params)
    rw = JSON.parse(rw.body)[0]["response"]
    binding.pry
    response = response.merge(rw)
    binding.pry
    response
    #r1 = request_sds(path: '/score/sbrs/json?ip=', body: params)
    #r2 = request_sds(path: '/score/webcat/json?url=', body: params)
    #r3 = request_sds(path: '/score/sbrs/json?ip=', body: params)
    #binding.pry
    #r4 = request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params)
    #binding.pry
    #
    # am I an IP?
    # => do IP stuff
    # otherwise assume domain/URL
    # => and do URL stuff
    #
    #response = request_sds(path: '/score/sbrs/json?ip=', body: params)
    #return response.body if raw == true
    #JSON.parse(response.body)[0]["response"]
    # this should return {"sbrs": {"score": "<score>"}}
    # where <score> is either between -10 and 10 (inclusive)
    # or noscore
  end

  def self.wheeer(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    binding.pry
    #r1 = request_sds(path: '/score/sbrs/json?ip=', body: params)
    #r2 = request_sds(path: '/score/webcat/json?url=', body: params)
    #r3 = request_sds(path: '/score/sbrs/json?ip=', body: params)
    binding.pry
    r4 = request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params)
    binding.pry
    #
    # am I an IP?
    # => do IP stuff
    # otherwise assume domain/URL
    # => and do URL stuff
    #
    response = request_sds(path: '/score/sbrs/json?ip=', body: params)
    return response.body if raw == true
    JSON.parse(response.body)[0]["response"]
    # this should return {"sbrs": {"score": "<score>"}}
    # where <score> is either between -10 and 10 (inclusive)
    # or noscore
  end

  def self.wheer(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    response = request_sds(path: '/score/sbrs/json?ip=', body: params)
    return response.body if raw == true
    JSON.parse(response.body)[0]["response"]
    # this should return {"sbrs": {"score": "<score>"}}
    # where <score> is either between -10 and 10 (inclusive)
    # or noscore
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
