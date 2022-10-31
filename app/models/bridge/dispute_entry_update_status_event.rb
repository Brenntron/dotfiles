class Bridge::DisputeEntryUpdateStatusEvent < Bridge::BaseMessage
  def initialize
    super(channel: 'update-ticket',
          addressee: 'talos-intelligence')
    Delayed::Worker.logger.info("DisputeEntry update init")
  end

  def post_entries(entries)
    dispute = entries.first.dispute
    payload = entries.inject({}) do |message_data, entry|
      message_data[entry.hostlookup] = {
          company_dup: entry.is_possible_company_duplicate?,
          status: entry.status,
          resolution: entry.resolution,
          resolution_message: entry.resolution_comment,
          sugg_type: entry.suggested_disposition
      }
      message_data
    end
    post(message: {
        source_authority: 'talos-intelligence',
        source_key: dispute.ticket_source_key,
        ticket_entries: payload,
        status: dispute.status,
        ac_id: dispute.id
    })
  end

  handle_asynchronously :post_entries, :queue => "dispute_update", :priority => 2

  def post_entry(entry)
    Delayed::Worker.logger.info("DisputeEntry update event sending reply to bridge")
    post_entries([ entry ])
  end

  handle_asynchronously :post_entry, :queue => "dispute_update", :priority => 2
end
