class Bridge::FileRepUpdateStatusEvent < Bridge::BaseMessage
  def initialize(sender_data)
    super(channel: 'update-ticket',
          addressee: 'talos-intelligence')
  end

  def post(dispute, source_authority: @source_authority, source_key: @source_key)
    return_payload = {}
    return_payload[dispute.sha256_hash] = {
        ac_id: dispute.id,
        resolution: dispute.resolution,
        resolution_message: dispute.resolution_comment,
        status: dispute.status
    }
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: return_payload
    })
  end

  handle_asynchronously :post, :queue => "filerep_status_update"
end
