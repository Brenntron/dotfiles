class Bridge::PlatformEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'message-acknowledge',
          addressee: addressee)

    @source_authority = source_authority
    @source_key = source_key
  end

  def post(source_authority: @source_authority, source_key: @source_key, action: action)
    super(message: {
                    source_authority: source_authority,
                    source_key: source_key,
                    source_type: "Platform",
                    action: action
    })

  end

  handle_asynchronously :post, :queue => "platform_event_created", :priority => 1
end