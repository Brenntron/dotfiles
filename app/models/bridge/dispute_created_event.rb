class Bridge::DisputeCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil, ac_id: nil)
    super(channel: 'ticket-acknowledge',
          addressee: addressee)
    Delayed::Worker.logger.info("Dispute created event initializing")
    @ac_id = ac_id
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(payload, case_email, source_authority: @source_authority, source_key: @source_key, ac_id: @ac_id)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: payload,
                    case_email: case_email, 
                    ac_status: Dispute::AC_SUCCESS,
                    ac_id: ac_id
                    })
    Delayed::Worker.logger.info("Dispute created event sending reply to bridge")
  end
  handle_asynchronously :post, :queue => "dispute_created", :priority => 1
end
