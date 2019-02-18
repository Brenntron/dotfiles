class Sbrs::ManualSbrs < Sbrs::Base
  FIELD_NAMES = %w{id ctime list_type mtime threat_cats url username state}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}


  attr_accessor *FIELD_SYMS


  #TODO: all of this needs to be refactored and improved.  Finished up quickly because of deadline.
  #Instructions:
  #get_sbrs_data({:ip => '1.2.3.4'})  <-- will return sbrs score for an ip
  #to get rulehit data for sbrs/email:
  #Sbrs::GetSbrs.get_sbrs_rules_for_ip('2.3.4.5') <--- will return an array of sbrs specific rules for provided ip string

  #get_wbrs_data({:url => 'www.google.com'}) or get_wbrs_data({:url => '2.3.4.5'}) <-- will return wbrs score and rulehits(ids) for url
  #get_rule_names_from_rulehits(response_returned_from_get_wbrs_data) <-- will return an array of rulehit mnemonics provided by the response package of above method


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
    sbrs_return = JSON.parse(sbrs_response.body)
    sbrs_return = sbrs_return[0]['response']

    sbrs_return
  end

  def self.parse_wbrs(wbrs_response)
    wbrs_return = JSON.parse(wbrs_response.body)
    wbrs_return = wbrs_return[0]['response']

    wbrs_return
  end

  def self.call_sbrs(params, type: nil)
    parse_sbrs(request_sds(path: '/score/sbrs/json?ip=', body: params, type: type))
  end

  def self.call_wbrs(params, type:nil)
    parse_wbrs(request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params, type: type))
  end

  def self.where(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    {}.merge(call_sbrs(params)).merge(call_wbrs(params))
    # this should return {"sbrs": {"score": "<score>"}}
    # where <score> is either between -10 and 10 (inclusive)
    # or noscore
  end

  def self.get_rule_names_from_rulehits(rep_data)
    all_rules = Sbrs::Base.rules_matchup

    uri_rules = []
    rep_data["wbrs-rulehits"].each do |rule_id|
      rule_id = rule_id.to_s
      if all_rules[rule_id].present?
        uri_rules.append(all_rules[rule_id]["mnemonic"])

      else
        uri_rules.append(rule_id)

      end
    end
    uri_rules

  end

  def self.get_wbrs_data(conditions)
    params = stringkey_params(conditions)
    response = {}

    rw = request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params, type: 'wbrs')
    rw = JSON.parse(rw.body)[0]["response"]

    response = response.merge(rw)

    response

  end

  def self.get_sbrs_data(conditions)
    params = stringkey_params(conditions)
    response = {}

    rs = request_sds(path: '/score/sbrs/json?ip=', body: params)
    rs = JSON.parse(rs.body)[0]["response"]

    response = response.merge(rs)

    response
  end

end
