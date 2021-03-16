require 'service-connection-status_services_pb'

class Beaker::ConnectionStatus < Beaker::BeakerBase

  def self.stub
    @stub = Talos::Service::ConnectionStatus::Stub.new(hostport, creds)
  end

  def stub
    self.class.stub
  end

  # Request a Connection Status message.
  # rpc :ConnectionStatus, ::Talos::ConnectionStatus::Request, ::Talos::ConnectionStatus::Reply
  def self.connection_status
    stub.connection_status(Talos::ConnectionStatus::Request.new)
  end
end
