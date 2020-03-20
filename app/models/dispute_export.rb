class DisputeExport
  attr_reader :disputes

  def initialize(disputes_given)
    @disputes = disputes_given
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

  EXPORT_HEADERS =
      ['Priority',
       'Case ID',
       'Status',
       'Entry Count',
       'Assignee',
       'Customer Name',
       'Customer Email',
       'Customer Company',
       'Company URL',
       'Submission Type',
       'Time Submitted',
       'Last Updated',
       'Age',
       'Dispute Entry',
       'Dispute Entry Status',
       'Suggested Disposition',
       'Category',
       'WBRS Score',
       'WBRS Total Rule Hits',
       'SBRS Score',
       'SBRS Total Rule Hits',
       'Important?',
       'Resolution',
       'Last Email Date',
       'Email Count',
       'Resolution Comments']

  def workbook
    unless @workbook
      @workbook = RubyXL::Workbook.new
      worksheet = @workbook[0]


      sheet_insert_row(worksheet, EXPORT_HEADERS, "h1")

      @disputes.each do |dispute|
        dispute.dispute_entries.each do |dispute_entry|
          sheet_insert_row(worksheet,
                           [dispute_entry.dispute.priority,
                            dispute_entry.dispute.case_id_str,
                            dispute_entry.dispute.status,
                            dispute_entry.dispute.dispute_entries.count,
                            dispute_entry.dispute.user.cvs_username,
                            dispute_entry.dispute.customer.name,
                            dispute_entry.dispute.customer.email,
                            dispute_entry.dispute.customer.company.name,
                            dispute_entry.dispute.org_domain,
                            dispute.submission_type,
                            dispute_entry.dispute.case_opened_at.strftime("%FT%T"),
                            dispute_entry.dispute.updated_at.strftime("%FT%T"),
                            ApplicationRecord.humanize_secs(Time.now - dispute_entry.dispute.case_opened_at),
                            dispute_entry.hostlookup,
                            dispute_entry.status,
                            dispute_entry.suggested_disposition,
                            dispute_entry.primary_category,
                            dispute_entry.wbrs_score,
                            dispute_entry.dispute_rule_hits.wbrs_rule_hits.count,
                            dispute_entry.sbrs_score,
                            dispute_entry.dispute_rule_hits.sbrs_rule_hits.count,
                            dispute_entry.is_important,
                            dispute_entry.resolution,
                            dispute_entry.latest_email_date,
                            dispute_entry.dispute.dispute_emails.count,
                            dispute_entry.resolution_comment ])
        end
      end
    end

    @workbook
  end

  def to_s
    workbook.stream.string
  end
end
