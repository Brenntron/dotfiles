class Beaker::BeakerBase

  def self.hostport
    @hostport ||= Rails.configuration.beaker.hostport
  end

  def self.ca_cert
    @ca_cert ||= File.open(Rails.configuration.beaker.ca_cert_file).read
  end

  def self.creds
    @creds ||= GRPC::Core::ChannelCredentials.new(ca_cert)
  end

  def self.get_app_info
    Talos::AppInfo.new(
      device_id: Rails.configuration.app_info.device_id,
      product_family: Rails.configuration.app_info.product_family,
      product_id: Rails.configuration.app_info.product_id,
      product_version: Rails.configuration.app_info.product_version
    )
  end

  def get_app_info
    self.class.get_app_info
  end

  def self.get_connection(guid=nil)
    Talos::IPConnection.new(
        direction: Talos::IPConnection::Direction::IP_DIR_OUT,
        proto: Talos::IPConnection::Protocol::IP_PROTO_TCP,
        guid: guid || SecureRandom.uuid
    )
  end

  def self.get_ip_endpoint(ip)

    begin
      ip_addr = IPAddr.new(ip)
      if ip_addr.ipv4?
        Talos::IPEndpoint.new(ipv4_addr: ip_addr.to_i)
      elsif ip_addr.ipv6?
        Talos::IPEndpoint.new(ipv6_addr: ip_addr.hton)
      end
    rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
      assembled_ip = [ip.to_i].pack('N').unpack('C4').join('.')
      ip_addr = IPAddr.new(assembled_ip)
      Talos::IPEndpoint.new(ipv4_addr: ip_addr.to_i)
    end

  end
end
