class EnrichmentService::EnrichmentServiceBase

  def self.hostport
    @hostport ||= Rails.configuration.enrichment_service.hostport
  end

  def self.cert
    @cert ||=
        if Rails.configuration.enrichment_service.cert_file.present?
          File.open(Rails.configuration.enrichment_service.cert_file).read
        else
          raise EnrichmentService::EnrichmentServiceError, "Missing cert file"
        end
  end

  def self.key
    @cert_key ||=
        if Rails.configuration.enrichment_service.key_file.present?
          File.open(Rails.configuration.enrichment_service.key_file).read
        else
          raise EnrichmentService::EnrichmentServiceError, "Missing key file"
        end
  end

  def self.creds
    @creds ||= GRPC::Core::ChannelCredentials.new(nil, key, cert)
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
