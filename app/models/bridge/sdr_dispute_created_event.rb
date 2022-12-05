class Bridge::SdrDisputeCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil, ac_id: nil, ticket_status: nil)
    super(channel: 'ticket-acknowledge',
          addressee: addressee)
    Delayed::Worker.logger.info("SDR Dispute create init")
    @ac_id = ac_id
    @source_authority = source_authority
    @source_key = source_key
    @ticket_status = ticket_status
  end

  def post(payload, source_authority: @source_authority, source_key: @source_key, ac_id: @ac_id)
    super(message: {ac_id: ac_id,
                    source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: payload,
                    ac_status: SenderDomainReputationDispute::AC_SUCCESS,
                    ticket_status: @ticke_status
    })
    Delayed::Worker.logger.info("SDR Dispute create even sending to bridge")
  end

  handle_asynchronously :post, :queue => "sdr_dispute_created", :priority => 1
end
