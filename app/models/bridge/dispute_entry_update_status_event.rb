class Bridge::DisputeEntryUpdateStatusEvent < Bridge::BaseMessage
  def initialize
    super(channel: 'dispute-entry-update-status',
          addressee: 'talos-intelligence')
  end

  def post_entries(entries)
    message = entries.inject({}) do |message_data, entry|
      message_data[entry.hostlookup] = {
          company_dup: entry.is_possible_company_duplicate?,
          status: entry.ti_status,
          resolution: entry.resolution,
          resolution_message: entry.resolution_comment
      }
      message_data
    end
    post(message: message)
  end

  def post_entry(entry)
    post_entries([ entry ])
  end
end
