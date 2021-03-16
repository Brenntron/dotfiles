class Beaker::BeakerBase
  SERVICE_STUB = Talos::Service::ConnectionStatus::Stub

  def self.ca_cert
    @ca_cert ||= GRPC::Core::ChannelCredentials.new(File.open(Rails.configuration.beaker.ca_cert_file).read)
  end

  def self.creds
    @creds ||= GRPC::Core::ChannelCredentials.new(File.open('/usr/local/etc/trusted-certificates.pem').read)
  end

  def self.new_stub
    SERVICE_STUB.new(Rails.configuration.beaker.hostport, creds)
  end

  # Makes a gRPC request.
  # example: call_request(Talos::GUID, :gen_guid, type_of_guid: type_of_guid)
  # @param [Module] buffer_module module generated from buffer compiler which has the Request constant.
  # @param [Symbol] method the symbol for the method name.
  # @param [Array] args argument list for the remote method call.
  def self.call_single_request(buffer_module, method, *args)
    byebug
    stub = new_stub
    stub.send(method, buffer_module::Request.new(*args))
  end

  def call_single_request(buffer_module, method, *args)
    self.class.call_single_request(buffer_module, method, *args)
  end
end
