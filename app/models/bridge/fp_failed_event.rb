class Bridge::FpFailedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'fp-failed-event',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(source_key: @source_key, ac_status: "UNSENT")
    super(message: {source_key: source_key,
                    ac_status: ac_status})
  end
  handle_asynchronously :post, :queue => "fp_failed"
end
