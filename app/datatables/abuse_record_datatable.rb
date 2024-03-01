class AbuseRecordDatatable < AjaxDatatablesRails::Base

  def initialize(params, user)
    @user = user
    super(params, {})
  end

  #def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
  #  @view_columns ||={
        #complaint_entry_id:       {source: "Cluster.cluster_id", cond: :eq, searchable: true, orderable: true},
      # age:      {source: "Cluster.age", cond: :eq, searchable: true, orderable: true},
        #domain:   {source: "Cluster.domain", cond: :eq, searchable: true, orderable: true},
      # cluster_entries_count: {source: "Cluster.entry_count", cond: :eq, searchable: false, orderable: true},
      # customer_name: {source: "Complaint.customer_name", cond: :eq, searchable: true, orderable: true},
        #global_volume: {source: "Cluster.global_volume", cond: :eq, searchable: true, orderable: true},
        #age:  {source: "Cluster.ctime", cond: :eq, searchable: true, orderable: true},
    }
  #end

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
