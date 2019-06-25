class Bridge::FileRepUpdateStatusEvent < Bridge::BaseMessage
  def initialize(sender_data)
    super(channel: 'update-ticket',
          addressee: 'talos-intelligence')
  end

  def post(payload, source_authority: @source_authority, source_key: @source_key)
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: payload
    })
  end

  handle_asynchronously :post, :queue => "filerep_status_update"
end
