class Sbrs::ManualSbrs < Sbrs::Base
  FIELD_NAMES = %w{id ctime list_type mtime threat_cats url username state}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}


  attr_accessor *FIELD_SYMS


  #TODO: all of this needs to be refactored and improved.  See Sbrs::Base class.
  #Instructions:
  #get_sbrs_data({:ip => '1.2.3.4'})  <-- will return sbrs score for an ip
  #to get rulehit data for sbrs/email:
  #Sbrs::GetSbrs.get_sbrs_rules_for_ip('2.3.4.5') <--- will return an array of sbrs specific rules for provided ip string

  #get_wbrs_data({:url => 'www.google.com'}) or get_wbrs_data({:url => '2.3.4.5'}) <-- will return wbrs score and rulehits(ids) for url
  #get_rule_names_from_rulehits(response_returned_from_get_wbrs_data) <-- will return an array of rulehit mnemonics provided by the response package of above method


  def initialize(attributes = {})
    if attributes.keys.present?
      attributes.keys.each do |attr|
        if !FIELD_NAMES.include?(attr)
          self.class.module_eval { attr_accessor attr.to_sym}
        end
      end
    end
    super
  end

  def self.call_sbrs(params, type: nil)
    parse_sbrs(request_sds(path: '/score/sbrs/json?ip=', body: params, type: type))
  end

  def self.call_wbrs(params, type: nil)
    parse_wbrs(request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params, type: type))
  end

  def self.call_wbrs_webcat(params, type: nil)
    sds_response = parse_wbrs(request_sds(path: '/score/webcat/json?url=', body: params, type: type))
    webcatlist = parse_wbrs(request_sds(path: '/labels/webcat/json', body: params, type: type))

    if sds_response["webcat"]["cat"] == 'nocat'
      nil.to_s
    else
      webcatlist["#{sds_response["webcat"]["cat"]}"]["name"]
    end
  end

  def self.get_rule_names_from_rulehits(rep_data)
    all_rules = Sbrs::Base.rules_matchup

    uri_rules = []

    if rep_data["wbrs-rulehits"].present?
      rep_data["wbrs-rulehits"].each do |rule_id|
        rule_id = rule_id.to_s
        if all_rules[rule_id].present?
          uri_rules.append(all_rules[rule_id]["mnemonic"])

        else
          uri_rules.append(rule_id)

        end
      end
    end
    uri_rules

  end

  def self.get_wbrs_data(conditions)
    params = stringkey_params(conditions)
    response = {}

    rw = request_sds(path: '/score/wbrs;wbrs-rulehits/json?url=', body: params, type: 'wbrs')

    begin
      data = JSON.parse(rw.body)[0]["response"]
    rescue
      # Return dummy data since we assume that the request_sds call failed

      if JSON.parse(rw)['response'].present?
        data = {}
        data['wbrs-rulehits'] = nil
        data['wbrs'] = {}
        data['wbrs']['score'] = nil

      end
    end

    response = response.merge(data)

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




  protected   ##########################################################################################################

  def self.new_from_attributes(attributes)
    new(attributes)
  end

  def self.parse_sbrs(sbrs_response)
    sbrs_return = JSON.parse(sbrs_response.body)
    sbrs_return = sbrs_return[0]['response']

    sbrs_return
  end

  def self.parse_wbrs(wbrs_response)
    wbrs_return = JSON.parse(wbrs_response.body)
    #sometimes we get responses back that are arrays
    #sometimes we get responses that are hashes...
    #i hate the wubya bee arr ess API
    if wbrs_return.kind_of?(Array)
      wbrs_return = wbrs_return[0]['response']
    end
    wbrs_return
  end
end
