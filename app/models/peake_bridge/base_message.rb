module PeakeBridge
  class BaseMessage < BasicPeakeBridge
    def initialize(channel:, addressee:)
      super(channel: channel,
            addressee: addressee,
            host: Rails.configuration.peakebridge['peakebridge'].host,
            port: Rails.configuration.peakebridge['peakebridge'].port,
            ssl: Rails.configuration.peakebridge['peakebridge'].ssl,
            uri_base: Rails.configuration.peakebridge['peakebridge'].uri_base)
    end
  end
end
