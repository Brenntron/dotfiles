class AutoResolve < ActiveModel
  attr_accessor :address_type, :address, :status

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

  def check_complaints

  end

  def check_virus_total

  end

  def check_umbrella

  end

  def check_sources
    if Rails.configuration.check_complaints
      check_complaints
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
  def self.create_from_payload(address_type:, address:)
    address_type_attr =
        case address_type
          when 'IP'
            ADDRESS_TYPE_IP
          when /\A[[:alpha:]]+:/
            ADDRESS_TYPE_URI
          else
            ADDRESS_TYPE_DOMAIN
        end

    auto_resolve = new(address_type: address_type_attr, address: address)
    auto_resolve.check_sources
    auto_resolve
  end
end
