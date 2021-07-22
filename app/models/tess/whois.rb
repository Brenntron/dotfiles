require 'service-tess_services_pb'

class Tess::Whois

  def self.hostport
    @hostport ||= "#{Rails.configuration.tess.host}:#{Rails.configuration.tess.port || 80}"
  end

  def self.ca_cert
    # @ca_cert ||= File.open('/Users/marlpier/projects/analyst-console-escalations/whois/server.crt').read
    @ca_cert ||= File.open(Rails.configuration.tess.ca_cert_file).read
  end

  def self.cert
    # @cert ||= File.open('/Users/marlpier/projects/analyst-console-escalations/whois/client.crt').read
    @cert ||= File.open(Rails.configuration.app_info.client_cert_file).read
  end

  def self.cert_key
    # @cert_key ||= File.open('/Users/marlpier/projects/analyst-console-escalations/whois/client.key').read
    @cert_key ||= File.open(Rails.configuration.app_info.pkey_file).read
  end

  def self.creds
    @creds ||= GRPC::Core::ChannelCredentials.new(ca_cert, cert_key, cert)
    # @creds ||= GRPC::Core::ChannelCredentials.new(ca_cert)
  end

  def self.get_app_info
    # Talos::AppInfo.new(
    #   device_id: Rails.configuration.app_info.device_id,
    #   product_family: Rails.configuration.app_info.product_family,
    #   product_id: Rails.configuration.app_info.product_id,
    #   product_version: Rails.configuration.app_info.product_version
    # )
    Talos::AppInfo.new(
      device_id: '__beting_was_here',
      product_family: '__beting_was_here',
      product_id: '__beting_was_here',
      product_version: '__beting_was_here'
    )
  end

  def self.remote_stub
    @remote_stub ||= Talos::Service::TESS::Stub.new(hostport, creds)
    # @remote_stub ||= Talos::Service::TESS::Stub.new(hostport, :this_channel_is_insecure)
  end

  def self.whois_query(name)
    whois_search_request = Talos::TESS::WhoisSearchRequest.new(app_info: get_app_info, search_string: name)
    response = remote_stub.whois_query(whois_search_request)

    unless :WHOIS_SUCCESS == response.status
      raise "Failure getting whois information -- #{response.status_message}"
    end

    response.result
  end
end

