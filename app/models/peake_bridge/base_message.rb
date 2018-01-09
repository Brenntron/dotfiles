module PeakeBridge
  class BaseMessage < BasicPeakeBridge
    def initialize(channel:, addressee:)
      super(channel: channel,
            sender: 'analyst-console',
            addressee: addressee,
            host: Rails.configuration.peakebridge['peakebridge'].host,
            port: Rails.configuration.peakebridge['peakebridge'].port,
            ssl_mode: Rails.configuration.peakebridge['peakebridge'].ssl_mode,
            uri_base: Rails.configuration.peakebridge['peakebridge'].uri_base)
    end
  end
end
