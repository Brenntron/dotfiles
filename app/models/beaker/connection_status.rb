require 'service-connection-status_services_pb'

class Beaker::ConnectionStatus < Beaker::BeakerBase

  # Request a Connection Status message.
  # rpc :ConnectionStatus, ::Talos::ConnectionStatus::Request, ::Talos::ConnectionStatus::Reply
  def self.connection_status
    call_single_request(Talos::ConnectionStatus, :connection_status)
  end
end
