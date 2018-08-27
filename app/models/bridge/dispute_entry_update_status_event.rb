class Bridge::DisputeEntryUpdateStatusEvent < Bridge::BaseMessage
  def initialize
    super(channel: 'update-ticket',
          addressee: 'talos-intelligence')
  end

  def post_entries(entries)
    dispute = entries.first.dispute
    payload = entries.inject({}) do |message_data, entry|
      message_data[entry.hostlookup] = {
          company_dup: entry.is_possible_company_duplicate?,
          status: entry.ti_status,
          resolution: entry.resolution,
          resolution_message: entry.resolution_comment
      }
      message_data
    end
    post(message: {
        source_authority: 'talos-intelligence',
        source_key: dispute.ticket_source_key,
        ticket_entries: payload
    })
  end

  handle_asynchronously :post_entries, :queue => "dispute_update"

  def post_entry(entry)
    post_entries([ entry ])
  end

  handle_asynchronously :post_entry, :queue => "dispute_update"
end
