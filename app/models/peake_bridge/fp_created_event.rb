module PeakeBridge
  class FpCreatedEvent < BaseMessage
    def initialize(addressee:, source_authority: nil, source_key: nil)
      super(channel: 'fp-created-event',
            addressee: addressee)
      @source_authority = source_authority
      @source_key = source_key
    end

    def post(false_positive_id:, source_authority: @source_authority, source_key: @source_key)
      super(message: {false_positive_id: false_positive_id,
                      source_authority: source_authority,
                      source_key: source_key})
    end
  end
end
