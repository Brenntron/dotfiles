require 'service-ipd_services_pb'

class Beaker::Ipd < Beaker::BeakerBase

  def self.stub
    @stub = Talos::Service::IPD::Stub.new(hostport, creds)
  end

  def stub
    self.class.stub
  end

  # Request organization information based on domain. See the
  # `DomainInfoRequest` and `DomainInfoReply` messages in `ipd.proto` for
  # details on the structure of the request and response.
  # rpc :QueryDomainInfo, ::Talos::IPD::DomainInfoRequest, ::Talos::IPD::DomainInfoReply
  def query_domain_info(name)
    stub.query_domain_info(Talos::IPD::DomainInfoRequest.new(name: name))
  end
end
