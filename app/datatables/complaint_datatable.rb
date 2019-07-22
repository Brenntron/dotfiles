class ComplaintDatatable < AjaxDatatablesRails::Base
  extend Forwardable

  def_delegators :@view, :link_to, :edit_escalations_webcat_complaint_path, :escalations_webcat_complaints_path, :content_tag, :concat

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||={
      id:       {source: "Complaint.id", cond: :eq, searchable: true, orderable: true},
      age:      {source: "Complaint.age", cond: :eq, searchable: true, orderable: true},
      status:   {source: "Complaint.status", cond: :eq, searchable: true, orderable: true},
      complaint_entries_count: {source: "Complaint.entry_count", cond: :eq, searchable: false, orderable: true},
      customer_name: {source: "Complaint.customer_name", cond: :eq, searchable: true, orderable: true},
    }
  end

  def data
    records.map do |record|
      {
          id:         record.id,
          age:        record.age,
          status:     record.status,
          entry_count: record.entries.count,
          customer_name:   record.customer.name,
      }
    end
  end

  private

  def get_raw_records
    Complaint.all
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
