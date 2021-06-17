class Bridge::GenericAck < Bridge::BaseMessage
  def initialize(sender_data, addressee:)
    super(channel: 'generic-ack',
          addressee: addressee)
    @sender_data = sender_data
  end

  def post
    super(message: {sender_data: @sender_data})
    Delayed::Worker.logger.info("Generic Ack sending reply to bridge")
  end
  # handle_asynchronously :post, :queue => "generic_ack"
end