class AutoResolve
  include ActiveModel

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

  def virus_total_api_key
    Rails.configuration.virus_total_api_key
  end

  def virus_total_query_string(url_input)
    "apikey=#{virus_total_api_key}&resource=#{url_input}"
  end

  def virus_total_request(url_input)
    virus_total_url = 'https://www.virustotal.com/vtapi/v2/url/report'
    @request = HTTPI::Request.new("#{virus_total_url}?#{virus_total_query_string(url_input)}")
    @request.ssl = true
    @request.auth.ssl.verify_mode = :peer
    @request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    @request
  end

  def call_virus_total(url_input)
    request = virus_total_request(url_input)
    response = HTTPI.get(request)
    JSON.parse(response.body)
  end

  def virus_total_scan_names
    %w{Kaspersky Sophos Avira Google\ Safebrowsing BitDefender}
  end

  # Checks the Virus Total system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_virus_total(url_input)
    scans = call_virus_total(url_input)['scans']
    if virus_total_scan_names.find {|scan_key| scans[scan_key]['detected']}
      self.status = STATUS_MALICIOUS
    end
  end

  # Checks the Umbrella system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_umbrella

  end

  # Checks the remote systems.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_sources
    if Rails.configuration.check_complaints
      check_complaints(rule_hits: self.rule_hits)
      return if self.status
    end

    if Rails.configuration.check_virus_total
      check_virus_total(self.address)
      return if self.status
    end

    if Rails.configuration.check_umbrella
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
    auto_resolve.check_sources
    auto_resolve
  end
end
