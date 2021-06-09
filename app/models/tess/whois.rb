# move to TESS
require 'sb-api_services_pb'
require 'service-tess_services_pb'

class Tess::Whois

  def self.hostport
    @hostport ||= 'tess.sl.talos.cisco.com:443'
  end

  def self.ca_cert
    @ca_cert ||= File.open('/Users/marlpier/projects/analyst-console-escalations/whois/server.crt').read
  end

  def self.cert
    @cert ||= File.open('/Users/marlpier/projects/analyst-console-escalations/whois/client.crt').read
  end

  def self.cert_key
    @cert_key ||= File.open('/Users/marlpier/projects/analyst-console-escalations/whois/client.key').read
  end

  def self.creds
    # @creds ||= GRPC::Core::ChannelCredentials.new(ca_cert, cert, cert_key)
    @creds ||= GRPC::Core::ChannelCredentials.new(ca_cert)
    # @creds ||= GRPC::Core::ChannelCredentials.new(ca_cert)
  end

  def self.get_app_info
    Talos::AppInfo.new(
      device_id: Rails.configuration.app_info.device_id,
      product_family: Rails.configuration.app_info.product_family,
      product_id: Rails.configuration.app_info.product_id,
      product_version: Rails.configuration.app_info.product_version
    )
  end

  # Tried Google auth procedure
  # def self.creds
  #   server_creds = GRPC::Core::ChannelCredentials.new(ca_cert)
  #   client_creds = GRPC::Core::CallCredentials.new(proc {{}})
  #   server_creds.compose(client_creds)
  # end

  def self.remote_stub
    # @remote_stub ||= SBAPI::Stub.new('aeon-denaliipediainternalsb-api.marathon.l4lb.thisdcos.directory:10069', creds)
    # @remote_stub ||= SBAPI::Stub.new(hostport, creds)
    # @remote_stub ||= SBAPI::Stub.new(hostport, :this_channel_is_insecure)
    # @remote_stub ||= Talos::Service::TESS::Stub.new(hostport, creds)
    @remote_stub ||= Talos::Service::TESS::Stub.new(hostport, :this_channel_is_insecure)
  end

  def remote_stub
    self.class.remote_stub
  end

  def lookup(name)
    byebug
    # remote_stub.who_is_query(WhoIsSearchRequest.new(search_string: name))
    whois_search_request = Talos::TESS::WhoisSearchRequest.new(app_info: self.class.get_app_info, search_string: name)
    remote_stub.whois_query(whois_search_request)
  end
end


# # require 'grpc'
# # require 'sb-api_pb'
# require 'sb-api_services_pb'
#
#
# ca_cert = File.open('/Users/marlpier/projects/analyst-console-escalations/whois/server.crt').read
# cert = File.open('/Users/marlpier/projects/analyst-console-escalations/whois/client.crt').read
# cert_key = File.open('/Users/marlpier/projects/analyst-console-escalations/whois/client.key').read
# creds = GRPC::Core::ChannelCredentials.new(ca_cert, cert, cert_key)
#
# #stub = SBAPI::Stub.new(hostport, :this_channel_is_insecure)
# stub = SBAPI::Stub.new('ipedia-api.sl.talos.cisco.com:443', creds)
#
# stub.who_is_query(WhoIsSearchRequest.new(search_string: 'cisco.com'))

