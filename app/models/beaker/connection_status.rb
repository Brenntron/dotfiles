require 'service-connection-status_services_pb'

class Beaker::ConnectionStatus < Beaker::BeakerBase

  def self.remote_stub
    @remote_stub = Talos::Service::ConnectionStatus::Stub.new(hostport, creds)
  end

  def remote_stub
    self.class.remote_stub
  end

  # Request a Connection Status message.
  # rpc :ConnectionStatus, ::Talos::ConnectionStatus::Request, ::Talos::ConnectionStatus::Reply
  def self.connection_status
    remote_stub.connection_status(Talos::ConnectionStatus::Request.new)
  end
end
