class DisputeExport
  attr_reader :disputes

  def initialize(disputes_given, user_preferences)
    @disputes = disputes_given
    @user_preferences = user_preferences
  end

  def sheet_insert_row(worksheet, data, format = nil)
    data_insertion_index = worksheet.sheet_data.rows.count
    data.each_with_index do |new_data, i|
      worksheet.add_cell(data_insertion_index, i, new_data)
      case format
      when "bold"
        worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
      when "h1"
        worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
        worksheet.sheet_data[data_insertion_index][i].change_font_size(14)
      when "h2"
        worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
        worksheet.sheet_data[data_insertion_index][i].change_font_size(12)
      end
    end
  end

  EXPORT_HEADERS = {
      'priority' => 'Priority',
      'case-id' => 'Case ID',
      'status' => 'Status',
      'resolution' => 'Resolution',
      'submission-type' => 'Ticket Type',
      'dispute' => 'Dispute',
      'owner' => 'Assignee',
      'time-submitted' => 'Time Submitted',
      'last-updated' => 'Last Updated',
      'age' => 'Age',
      'case-origin' => 'Case origin',
      'submitter-type' => 'Submitter Type',
      'submitter-org' => 'Submitter Org',
      'submitter-domain' => 'Submitter Domain',
      'contact-name' => 'Contact Name',
      'contact-email' => 'Contact Email',
      'status-comment' => 'Status Comment',
      'dispute-entry' => 'Dispute Entry',
      'entry-status' => 'Entry Status',
      'entry-resolution' => 'Entry Resolution',
      'suggested-disposition' => 'Suggested Disposition',
      'category' => 'Category',
      'wbrs-score' => 'WBRS Score',
      'wbrs-total-rule-hits' => 'WBRS Total Rule Hits',
      'sbrs-score' => 'SBRS Score',
      'sbrs-total-rule-hits' => 'SBRS Total Rule Hits'
  }


  def workbook
    unless @workbook
      @workbook = RubyXL::Workbook.new
      worksheet = @workbook[0]

      # filter export headers according to user filter setup
      visible_columns_setup = JSON.parse(@user_preferences.value).select{|_k, v| v}.keys
      headers_to_export = EXPORT_HEADERS.filter{|k, _v| visible_columns_setup.include?(k)}.values

      sheet_insert_row(worksheet, headers_to_export, "h1")

      @disputes.each do |dispute|
        dispute.dispute_entries.each do |dispute_entry|
          entry_data = {
             'priority' => dispute_entry.dispute.priority,
             'case-id' => dispute_entry.dispute.case_id_str,
             'status' => dispute_entry.dispute.status,
             'resolution' => dispute_entry.dispute.resolution,
             'submission-type' => dispute_entry.dispute.submission_type,
             'dispute' => Dispute.entry_content_for(dispute).first,
             'owner' => dispute_entry.dispute.user.cvs_username,
             'time-submitted' => dispute_entry.dispute.case_opened_at.strftime("%FT%T"),
             'last-updated' => dispute_entry.dispute.updated_at.strftime("%FT%T"),
             'age' => ApplicationRecord.humanize_secs(Time.now - dispute_entry.dispute.case_opened_at),
             'case-origin' => dispute_entry.dispute.ticket_source,
             'submitter-type' => dispute_entry.dispute.submitter_type,
             'submitter-org' => dispute_entry.dispute.customer_org,
             'submitter-domain' => dispute_entry.dispute.org_domain,
             'contact-name' => dispute_entry.dispute.customer_name,
             'contact-email' => dispute_entry.dispute.customer_email,
             'status-comment' => dispute_entry.dispute.status_comment,
             'dispute-entry' => dispute_entry.hostlookup,
             'entry-status' => dispute_entry.status,
             'entry-resolution' => dispute_entry.resolution,
             'suggested-disposition' => dispute_entry.suggested_disposition,
             'category' => dispute_entry.primary_category,
             'wbrs-score' => dispute_entry.wbrs_score,
             'wbrs-total-rule-hits' => dispute_entry.dispute_rule_hits.wbrs_rule_hits.count,
             'sbrs-score' => dispute_entry.sbrs_score,
             'sbrs-total-rule-hits' => dispute_entry.dispute_rule_hits.sbrs_rule_hits.count
          }

          # filter export data according to user filter setup
          filtered_enrty_data = entry_data.filter{|k, _v| visible_columns_setup.include?(k)}.values
          sheet_insert_row(worksheet, filtered_enrty_data)
        end
      end
    end

    @workbook
  end

  def to_s
    workbook.stream.string
  end
end
