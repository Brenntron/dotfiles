class AbuseRecordDatatable < AjaxDatatablesRails::ActiveRecord

  def initialize(params, user:)

    @user = user
    # @search_string = initialize_params['value'] # Native datatables search string
    super(params, {})
  end

  def view_columns
    @view_columns ||= {
        record_id:          {source: "AbuseRecord.id"},
        complaint_entry_id: {source: "ComplaintEntry.id"},
        url:                {source: "AbuseRecord.url", data: :url},
        date_resolved:      {source: "ComplaintEntry.case_resolved_at", data: :case_resolved_at, cond: :date_range},
        analyst:            {source: "AbuseRecord.submitter", data: :analyst},
        source:             {source: "AbuseRecord.source", data: :source},
        report_id:          {source: "AbuseRecord.report_ident", data: :report_id},
        date_sent:          {source: "AbuseRecord.created_at", data: :date_sent}
    }
  end

  def data
    records.map do |record|
      {
          record_id:                record.id,
          complaint_entry_id:       record.complaint_entry_id,
          url:                      record.url,
          date_resolved:            record.complaint_entry&.case_resolved_at,
          analyst:                  record.submitter,
          source:                   record.source,
          report_id:                record.report_ident,
          date_sent:                record.created_at
      }
    end
  end


  def get_raw_records
    AbuseRecord.all
  end

end
