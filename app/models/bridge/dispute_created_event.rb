class Bridge::DisputeCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'ticket-acknowledge',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(payload, case_email, source_authority: @source_authority, source_key: @source_key)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: payload,
                    case_email: case_email, 
                    ac_status: Dispute::AC_SUCCESS
                    })
  end
  handle_asynchronously :post, :queue => "dispute_created"
end
