class Bridge::ComplaintUpdateStatusEvent < Bridge::BaseMessage
  def initialize
    super(channel: 'update-ticket',
          addressee: 'talos-intelligence')
  end

  def post_entries(entries, options = {})
    source_key = options.fetch(:source_key) rescue @source_key 
    ac_id = options.fetch(:ac_id) rescue @ac_id
    complaint = entries.first.complaint
    payload = entries.inject({}) do |message_data, entry|
      message_data[entry.hostlookup] = {
          hostname: entry.hostlookup,
          status: entry.ti_status,
          resolution: entry.resolution,
          resolution_message: entry.resolution_comment,
          sugg_type: entry.suggested_disposition,
          category_list: entry.url_primary_category
      }
      message_data
    end

    post(message: {
        source_authority: 'talos-intelligence',
        source_key: source_key,
        ticket_entries: payload,
        status: complaint.status,
        ac_id: ac_id
    })
  end

  handle_asynchronously :post_entries, :queue => "complaint_update", :priority => 2

  def post_complaint(complaint)
    Delayed::Worker.logger.info("ComplaintUpdateStatus event sending reply to bridge")
    if complaint.ticket_source_key.present? && complaint.ticket_source != ::Complaint::SOURCE_RULEUI
      post_entries(complaint.complaint_entries, source_key: complaint.ticket_source_key, ac_id: complaint.id)
    end
  end
  handle_asynchronously :post_complaint, :queue => "complaint_update", :priority => 2
end
