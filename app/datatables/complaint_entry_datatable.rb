class ComplaintEntryDatatable < AjaxDatatablesRails::Base
  extend Forwardable

  def_delegators :@view, :link_to, :edit_escalations_webcat_complaint_path, :escalations_webcat_complaints_path, :content_tag, :concat

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||={
        complaint_id:   {source: "ComplaintEntry.complaint_id", cond: :eq, searchable: true, orderable: true},
        entry_id:       {source: "ComplaintEntry.entry_id", cond: :eq, searchable: true, orderable: true},
        age:            {source: "ComplaintEntry.age", cond: :eq, searchable: true, orderable: true},
        status:         {source: "ComplaintEntry.status", cond: :eq, searchable: true, orderable: true},
        customer_name:  {source: "ComplaintEntry.customer_name", cond: :eq, searchable: true, orderable: true},
        category:       {source: "ComplaintEntry.category", cond: :eq, searchable: true, orderable: true},
        wbrs_score:     {source: "ComplaintEntry.wbrs_score", cond: :eq, searchable: true, orderable: true},
        subdomain:      {source: "ComplaintEntry.subdomain", cond: :eq, searchable: true, orderable: true},
        domain:         {source: "ComplaintEntry.domain", cond: :eq, searchable: true, orderable: true},
        path:           {source: "ComplaintEntry.path", cond: :eq, searchable: true, orderable: true},
        ip_address:     {source: "ComplaintEntry.ip_address", cond: :eq, searchable: true, orderable: true},
        assigned_to:    {source: "ComplaintEntry.assigned_to", cond: :eq, searchable: true, orderable: true},

    }
  end

  def data
    records.map do |record|
      {
          complaint_id: record.complaint_id,
          entry_id:         record.entry_id,
          age:        record.age,
          status:     record.status,
          customer_name:   record.customer.name,
          category:       record.category,
          wbrs_score:     record.wbrs_score,
          subdomain:      record.subdomain,
          domain:         record.domain,
          path:           record.path,
          ip_address:     record.ip_address,
          assigned_to:     record.assigned_to,
      }
    end
  end

  private

  def get_raw_records
    ComplaintEntry.all
  end

  # ==== These methods represent the basic operations to perform on records
  # and feel free to override them

  # def filter_records(records)
  # end

  # def sort_records(records)
  # end

  # def paginate_records(records)
  # end

  # ==== Insert 'presenter'-like methods below if necessary
end
