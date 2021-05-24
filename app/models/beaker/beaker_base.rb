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
        device_id: ENV['DEVICE_ID'],
        product_family: ENV['PRODUCT_FAMILY'],
        product_id: ENV['PRODUCT_ID'],
        product_version: ENV['PRODUCT_VERSION']
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
    if ip.kind_of?(Integer)
      Talos::IPEndpoint.new(ipv4_addr: ip)
    else
      ip_addr = IPAddr.new(ip)
      Talos::IPEndpoint.new(
          ipv4_addr: ip_addr.to_i
      )
    end
  end
end
