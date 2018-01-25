class Bridge::BaseMessage < PeakeBridge::BasicPeakeBridge
  def initialize(channel:, addressee:)
    super(channel: channel,
          sender: 'analyst-console',
          addressee: addressee,
          host: Rails.configuration.peakebridge.host,
          port: Rails.configuration.peakebridge.port,
          ssl_mode: Rails.configuration.peakebridge.ssl_mode,
          uri_base: Rails.configuration.peakebridge.uri_base)
  end
end
