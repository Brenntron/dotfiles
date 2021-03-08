class Bridge::TicketConversionEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil, ac_id: nil)
    super(channel: 'convert-ticket',
          addressee: addressee)
    @ac_id = ac_id
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(payload, source_authority: @source_authority, source_key: @source_key, ac_id: @ac_id)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_information: payload,
                    case_email: case_email,
                    ac_id: ac_id
    })
  end
  handle_asynchronously :post, :queue => "ticket_conversion", :priority => 1
end
