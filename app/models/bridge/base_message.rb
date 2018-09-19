class Bridge::BaseMessage < PeakeBridge::BasicPeakeBridge
  def initialize(channel:, addressee:)
    super(channel: channel,
          sender: 'analyst-console',
          addressee: addressee,
          host: Rails.configuration.peakebridge.host,
          port: Rails.configuration.peakebridge.port,
          tls_mode: Rails.configuration.peakebridge.verify_mode,
          uri_base: Rails.configuration.peakebridge.uri_base,
          ca_file: Rails.configuration.peakebridge.ca_cert_file)
  end
end
