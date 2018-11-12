class Bridge::AmpFpCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'AmpFP-acknowledge',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(payload, source_authority: @source_authority, source_key: @source_key)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: payload,
                    ac_status: AmpFalsePositive::AC_SUCCESS
    })
  end

  handle_asynchronously :post, :queue => "amp_fp_created"
end
