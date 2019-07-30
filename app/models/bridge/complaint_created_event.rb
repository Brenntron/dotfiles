class Bridge::ComplaintCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil, ac_id: nil)
    super(channel: 'ticket-acknowledge',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
    @ac_id = ac_id
  end

  def post(payload, source_authority: @source_authority, source_key: @source_key, ac_id: @ac_id)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: payload,
                    ac_status: Complaint::AC_SUCCESS,
                    ac_id: ac_id
                    })
  end

  handle_asynchronously :post, :queue => "complaint_created"
end
