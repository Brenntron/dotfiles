class Bridge::FileRepCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil, ac_id:)
    super(channel: 'ticket-acknowledge',
          addressee: addressee)
    Delayed::Worker.logger.info("FileRep create init")
    @ac_id = ac_id
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(payload, source_authority: @source_authority, source_key: @source_key, ac_id: @ac_id)
    super(message: {ac_id: ac_id,
                    source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: payload,
                    ac_status: FileReputationDispute::AC_SUCCESS
    })
    Delayed::Worker.logger.info("FileRep create even sending to bridge")
  end

  handle_asynchronously :post, :queue => "file_reputation_dispute_created", :priority => 1
end