class Bridge::ComplaintFailedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'ticket-acknowledge',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(source_key: @source_key, ac_status: Complaint::AC_FAILED)
    super(message: {source_key: source_key,
                    ac_status: ac_status})
  end

  handle_asynchronously :post, :queue => "complaint_failed"
end
