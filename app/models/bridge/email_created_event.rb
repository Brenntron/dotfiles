class Bridge::EmailCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'email-acknowledge',
          addressee: addressee)
    Delayed::Worker.logger.info("Email Create Event Init")
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(source_authority: @source_authority, source_key: @source_key)
    Delayed::Worker.logger.info("Email Create event send to bridge")
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ac_status: Dispute::AC_SUCCESS
                    })
  end
  handle_asynchronously :post, :queue => "email_created"
end
