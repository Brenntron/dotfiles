class AutoResolve
  include ActiveModel::Model

  attr_accessor :address_type, :address, :status, :rule_hits, :internal_comment, :resolution_comment

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
  def uri?
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

  def append_comment(str)
    @internal_comment ||= ''
    @internal_comment += str

    @resolution_comment ||= ''
    @resolution_comment += str
  end

  def good_mnem?(rule_hit)
    %w{tuse a500 vsvd suwl wlw wlm wlh deli ciwl beaker_drl}.include?(rule_hit)
  end

  # Checks our complaints system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_complaints(rule_hits:)
    return unless rule_hits&.any?

    good_mnems = rule_hits.select{|rule_hit| good_mnem?(rule_hit)}
    if good_mnems.any?
      self.status = STATUS_NEW
      append_comment("BLS positive hit(s): #{good_mnems.join(', ')}; ")
    else
      append_comment('BLS: -; ')
    end
  end

  def virus_total_scan_names
    %w{Kaspersky Sophos Avira Google\ Safebrowsing BitDefender}
  end

  # Checks the Virus Total system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_virus_total(address: self.address)
    result = Virustotal::Scan.scan_hashes(address: address)
    if result && result['scans']
      all_scans = result['scans']
      scan_results = virus_total_scan_names.map do |scan_key|
        all_scans[scan_key]&.merge('name' => scan_key)
      end
      scan_hits = scan_results.select do |scan|
        scan && scan['detected']
      end
      if scan_hits.any?
        self.status = STATUS_MALICIOUS
        hit_messages = scan_hits.map {|scan| "#{scan['name']}: #{scan['result']}"}
        append_comment("#{hit_messages.join(', ')}; ")
      else
        append_comment('VT: -; ')
      end
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

  # TODO refactor into umbrella class like virustotal for easier testing.
  def call_umbrella(address: self.address)
    request = umbrella_request(address)
    response = HTTPI.post(request)
    case
      when 300 <= response.code
        Rails.logger.error("Umbrella http response #{response.code}")
        return nil
      when 200 != response.code
        Rails.logger.warn("Umbrella http response #{response.code}")
    end
    JSON.parse(response.body)
  end

  # Checks the Umbrella system.
  # Sets this object state to convention of NEW: human review needed, MALICIOUS: auto resolve, or nil unknown.
  def check_umbrella(address: self.address)
    result = call_umbrella(address: address)
    if result && result[address]
      verdict = result[address]
      if 0 > verdict['status']
        self.status = STATUS_MALICIOUS
        append_comment('Umbrella: malicious domain.; ')
      else
        append_comment('Umbrella: -; ')
      end
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
  # @param [Array<String>] rule_hits: collection of our rule hits as strings of mnem values
  def self.create_from_payload(address_type, address, rule_hits = nil)
    address_type_attr =
        case
          when 'IP' == address_type
            ADDRESS_TYPE_IP
          when /\A[[:alpha:]]+:/ =~ address
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
        resolution: malicious? ? 'Fixed -FN' : '',
        resolution_message: malicious? ? 'This URI/IP has been deemed malicious, and has been blacklisted.' : ''
    }
  end

  # Save the blacklist object.
  # @param [String] author: moniker of who is adding or updating this entry.
  # @return [Array<RepApi::Blacklist>] collection of responses with entry, expiration, and message.
  def publish_to_rep_api(author: 'reptooluser')
    raise 'Cannot blacklist address which has not been marked malicious through auto-resolve.' unless malicious?
    RepApi::Blacklist.add_from_hosts(hostnames: [ self.address ],
                                     classifications: [ 'malware' ],
                                     author: author,
                                     comment: 'TE SecHub-Auto')
  end
end
