class AbuseRecordDatatable < AjaxDatatablesRails::Base

  def initialize(params, user:)
    @user = user
    super(params, {})
  end

  def view_columns
    @view_columns ||= {
        complaint_entry_id: {source: "ComplaintEntry.id", cond: :like},
        url:                {source: "AbuseRecord.url", data: :url, cond: :like},
        date_resolved:      {source: "ComplaintEntry.case_resolved_at", data: :case_resolved_at, cond: :date_range},
        analyst:            {source: "AbuseRecord.submitter", data: :submitter, cond: :like},
        source:             {source: "AbuseRecord.source", data: :source, cond: :like},
        report_id:          {source: "AbuseRecord.report_ident", data: :report_ident, cond: :like},
        date_sent:          {source: "AbuseRecord.created_at", data: :created_at, cond: :date_range}
    }
  end

  def data
    records.map do |record|
      {
          complaint_entry_id:       record.complaint_entry_id,
          url:                      record.url,
          date_resolved:            record.complaint_entry.case_resolved_at,
          analyst:                  record.submitter,
          source:                   record.source,
          report_id:                record.report_ident,
          date_sent:                record.created_at
      }
    end
  end

  private

  def get_raw_records
    AbuseRecord.all
  end

end
