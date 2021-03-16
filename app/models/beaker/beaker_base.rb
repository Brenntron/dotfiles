class Beaker::BeakerBase

  def self.hostport
    @hostport = Rails.configuration.beaker.hostport
  end

  def self.ca_cert
    @ca_cert ||= GRPC::Core::ChannelCredentials.new(File.open(Rails.configuration.beaker.ca_cert_file).read)
  end

  def self.creds
    @creds ||= GRPC::Core::ChannelCredentials.new(File.open('/usr/local/etc/trusted-certificates.pem').read)
  end
end
