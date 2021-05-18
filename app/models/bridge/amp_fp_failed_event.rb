class Bridge::AmpFpFailedEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'AmpFP-acknowledge',
          addressee: addressee)
    @source_authority = source_authority
    @source_key = source_key
  end

  def post(source_key: @source_key, ac_status: AmpFalsePositive::AC_FAILED)
    Delayed::Worker.logger.info("AmpFp Failed event sending reply to bridge")
    super(message: {source_key: source_key,
                    ac_status: ac_status})
  end

  handle_asynchronously :post, :queue => "amp_fp_failed"
end
