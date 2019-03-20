class Bridge::GenericAck < Bridge::BaseMessage
  def initialize(sender_data, addressee:)
    super(channel: 'generic-ack',
          addressee: addressee)
    @sender_data = sender_data
  end

  def post
    byebug
    super(message: {sender_data: @sender_data})
  end
  # handle_asynchronously :post, :queue => "generic_ack"
end
