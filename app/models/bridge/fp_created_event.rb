class Bridge::FpCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'fp-created-event',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(false_positive_id:, bug_id:, source_authority: @source_authority, source_key: @source_key)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ac_response: 'A false positive record was created.',
                    ac_false_positive_id: false_positive_id,
                    ac_bug_id: bug_id})
  end

  handle_asynchronously :post, :queue => "fp_created"
end
