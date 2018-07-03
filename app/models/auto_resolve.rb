class AutoResolve < ActiveModel
  attr_accessor :address_type, :address, :status, :rule_hits

  ADDRESS_TYPE_IP           = 'IP'
  ADDRESS_TYPE_URI          = 'URI'
  ADDRESS_TYPE_DOMAIN       = 'DOMAIN'

  STATUS_NEW                = 'NEW'
  STATUS_MALICIOUS          = 'MALICIOUS'

  def ip?
    ADDRESS_TYPE_IP == self.address_type
  end

  def url?
    ADDRESS_TYPE_URI == self.address_type
  end

  def domain?
    ADDRESS_TYPE_DOMAIN == self.address_type
  end

  def new?
    STATUS_NEW == self.status
  end

  def malicious?
    STATUS_MALICIOUS == self.status
  end

  def good_mnem?(rule_hit)
    %w{tuse a500 vsvd suwl wlw wlm wlh deli ciwl beaker_drl}.include(rule_hit.mnem)
  end

  def check_complaints(rule_hits:)
    if rule_hits&.any? && rule_hits.find{|rule_hit| good_mnem?(rule_hit)}
      self.status = STATUS_NEW
    end
  end

  def check_virus_total

  end

  def check_umbrella

  end

  def check_sources
    if Rails.configuration.check_complaints
      check_complaints(rule_hits: self.rule_hits)
      return if self.status
    end

    if Rails.configuration.check_virus_total
      check_virus_total
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
