module PeakeBridge
  class FpCreatedEvent < BaseMessage
    def initialize(source_authority:, source_key:)
      super(channel: 'fp-created-event',
            addressee: 'snort-org')
      @source_authority = source_authority
      @source_key = source_key
    end

    def post(source_authority: @source_authority, source_key: @source_key)
      super(message: {source_authority: source_authority, source_key: source_key})
    end
  end
end
