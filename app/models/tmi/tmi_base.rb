class Tmi::TmiBase

  def self.hostport
    @hostport ||= Rails.configuration.tmi.hostport
  end

  def self.cacert
    @cacert ||=
        if Rails.configuration.tmi.ca_file.present?
          File.open(Rails.configuration.tmi.ca_file).read
        else
          raise Tmi::TmiError, "Missing ca file"
        end
  end

  def self.cert
    @cert ||=
        if Rails.configuration.tmi.cert_file.present?
          File.open(Rails.configuration.tmi.cert_file).read
        else
          raise Tmi::TmiError, "Missing cert file"
        end
  end

  def self.key
    @cert_key ||=
        if Rails.configuration.tmi.key_file.present?
          File.open(Rails.configuration.tmi.key_file).read
        else
          raise Tmi::TmiError, "Missing key file"
        end
  end

  def self.creds
    @creds ||= GRPC::Core::ChannelCredentials.new(cacert, key, cert)
  end

  def self.get_app_info
    Talos::AppInfo.new(
        device_id: Rails.configuration.app_info.device_id,
        product_family: Rails.configuration.app_info.product_family,
        product_id: Rails.configuration.app_info.product_id,
        product_version: Rails.configuration.app_info.product_version
    )
  end

  def self.get_ip_address(ip)
    begin
      ip_addr = IPAddr.new(ip)
      if ip_addr.ipv4?
        Talos::IPAddress.new(ipv4_addr: ip_addr.to_i)
      elsif ip_addr.ipv6?
        Talos::IPAddress.new(ipv6_addr: ip_addr.hton)
      end
    rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
      assembled_ip = [ip.to_i].pack('N').unpack('C4').join('.')
      ip_addr = IPAddr.new(assembled_ip)
      Talos::IPAddress.new(ipv4_addr: ip_addr.to_i)
    end
  end
end
