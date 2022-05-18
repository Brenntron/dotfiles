class Bridge::SdrDisputeUpdateStatusEvent < Bridge::BaseMessage
  #sender domain reputation disputes
  def initialize()
    super(channel: 'update-ticket',
          addressee: 'talos-intelligence')
    Delayed::Worker.logger.info("SDR Dispute update init")
  end

  def post(dispute, source_authority: @source_authority, source_key: @source_key)
    Delayed::Worker.logger.info("SDR Dispute update send to bridge")
    return_payload = {}
    return_payload[dispute.sender_domain_entry] = {
        ac_id: dispute.id,
        resolution: dispute.resolution,
        resolution_message: dispute.resolution_comment,
        status: dispute.status,
        sugg_type: dispute.suggested_disposition
    }
    super(message: {source_authority: source_authority,
                    source_key: source_key,
                    ticket_entries: return_payload,
                    ac_id: dispute.id,
                    status: dispute.status,
                    ticket_type: "FileReputationDispute"  # So TI knows to send escalated email if ticket originates on AC
    })
  end

  handle_asynchronously :post, :queue => "sdr_dispute_status_update", :priority => 2
end
