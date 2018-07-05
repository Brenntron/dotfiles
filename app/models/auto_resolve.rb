class AutoResolve
  include ActiveModel::Model

  attr_accessor :address_type, :address, :status, :rule_hits

  ADDRESS_TYPE_IP           = 'IP'
  ADDRESS_TYPE_URI          = 'URI'
  ADDRESS_TYPE_DOMAIN       = 'DOMAIN'

  STATUS_NEW                = 'NEW'
  STATUS_MALICIOUS          = 'MALICIOUS'

  # @return (Boolean) true if address type is IP.
  def ip?
    ADDRESS_TYPE_IP == self.address_type
  end

  # @return (Boolean) true if address type is a URL.
  def url?
    ADDRESS_TYPE_URI == self.address_type
  end

  # @return (Boolean) true if address type is a DNS domain name.
  def domain?
    ADDRESS_TYPE_DOMAIN == self.address_type
  end

  # @return [Boolean] true if auto resolve check is good and human needs to be in the loop.
  def new?
    STATUS_NEW == self.status
  end

  # @return [Boolean] true if auto resolve check is bad and entry auto resolves to malicious.
  def malicious?
    STATUS_MALICIOUS == self.status
  end

  def good_mnem?(rule_hit)
    %w{tuse a500 vsvd suwl wlw wlm wlh deli ciwl beaker_drl}.include?(rule_hit.mnem)
  end

  # Checks our complaints system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_complaints(rule_hits:)
    if rule_hits&.any? && rule_hits.find{|rule_hit| good_mnem?(rule_hit)}
      self.status = STATUS_NEW
    end
  end

  def virus_total_query_string(address)
    "apikey=#{Rails.configuration.virus_total.api_key}&resource=#{address}"
  end

  def virus_total_request(address)
    full_url = "#{Rails.configuration.virus_total.url}?#{virus_total_query_string(address)}"
    request = HTTPI::Request.new(full_url)
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    request
  end

  def call_virus_total(address: self.address)
    request = virus_total_request(address)
    response = HTTPI.get(request)
    JSON.parse(response.body)
  end

  def virus_total_scan_names
    %w{Kaspersky Sophos Avira Google\ Safebrowsing BitDefender}
  end

  # Checks the Virus Total system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_virus_total(address: self.address)
    result = call_virus_total(address: address)
    scans = result['scans']
    if virus_total_scan_names.find {|scan_key| scans[scan_key]['detected']}
      self.status = STATUS_MALICIOUS
    end
  end

  def umbrella_request(address)
    request = HTTPI::Request.new(Rails.configuration.umbrella.url)
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    request.headers['Authorization'] = "Bearer #{Rails.configuration.umbrella.api_key}"
    request.headers['Content-Type'] = 'application/json'
    request.body = [ address ].to_json
    request
  end

  def call_umbrella(address: self.address)
    request = umbrella_request(address)
    response = HTTPI.post(request)
    JSON.parse(response.body)
  end

  # Checks the Umbrella system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_umbrella(address: self.address)
    result = call_umbrella(address: address)
    verdict = result[address]
    if 0 > verdict['status']
      self.status = STATUS_MALICIOUS
    end
  end

  # Checks the remote systems.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_sources(rule_hits:)
    if Rails.configuration.complaints.check
      check_complaints(rule_hits: rule_hits)
      return if self.status
    end

    if Rails.configuration.virus_total.check
      check_virus_total
      return if self.status
    end

    if Rails.configuration.umbrella.check
      check_umbrella
      return if self.status
    end

    self.status = STATUS_NEW
  end

  # @param [String] address_type: 'IP' or 'URI/DOMAIN'
  # @param [String] address: ip address, uri, or domain
  # @param [Array<TBD>] rule_hits: collection of our rule hits
  def self.create_from_payload(address_type:, address:, rule_hits: nil)
    address_type_attr =
        case address_type
          when 'IP'
            ADDRESS_TYPE_IP
          when /\A[[:alpha:]]+:/
            ADDRESS_TYPE_URI
          else
            ADDRESS_TYPE_DOMAIN
        end

    auto_resolve = new(address_type: address_type_attr, address: address, rule_hits: rule_hits)
    auto_resolve.check_sources(rule_hits: rule_hits)
    auto_resolve
  end

  def entry_attributes
    {
        status: self.status,
        resolution: '',
        resolution_message: ''
    }
  end

  def ti_status
    {
    }
  end
end
