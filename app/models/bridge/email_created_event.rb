class Bridge::EmailCreatedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'email-acknowledge',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(source_authority: @source_authority, source_key: @source_key)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ac_status: Dispute::AC_SUCCESS
                    })
  end
  handle_asynchronously :post, :queue => "email_created"
end
