class Bridge::ComplaintUpdateStatusEvent < Bridge::BaseMessage
  def initialize
    super(channel: 'update-ticket',
          addressee: 'talos-intelligence')
  end

  def post_entries(entries, source_key: source_key)
    byebug
    payload = entries.inject({}) do |message_data, entry|
      message_data[entry.hostlookup] = {
          hostname: entry.hostlookup,
          status: entry.status,
          resolution: entry.resolution,
          resolution_message: entry.resolution_comment,
          suggested_disposition: entry.suggested_disposition,
          category_list: entry.url_primary_category
      }
      message_data
    end
    post(message: {
        source_authority: 'talos-intelligence',
        source_key: source_key,
        ticket_entries: payload
    })
  end

  def post_complaint(complaint)
    post_entries(complaint.complaint_entries, source_key: complaint.ticket_source_key)
  end
end
