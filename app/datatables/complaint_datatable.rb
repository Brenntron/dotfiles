class ComplaintDatatable < AjaxDatatablesRails::Base

  def_delegators :@view, :link_to, :edit_escalations_webcat_complaint_path, :escalations_webcat_complaints_path, :content_tag, :concat

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||={
      id:       {source: "Complaint.id", cond: :eq, searchable: true, orderable: true},
      tag:      {source: "Complaint.tag", cond: :eq, searchable: true, orderable: true},
      subdomain:{source: "Complaint.subdomain", cond: :eq, searchable: true, orderable: true},
      domain:   {source: "Complaint.domain", cond: :eq, searchable: true, orderable: true},
      path:     {source: "Complaint.path", cond: :eq, searchable: true, orderable: true},
      status:   {source: "Complaint.status", cond: :eq, searchable: true, orderable: true},
      age:      {source: "Complaint.age", cond: :eq, searchable: true, orderable: true},
      customer: {source: "Complaint.customer", cond: :eq, searchable: true, orderable: true},
      wbrs_core:{source: "Complaint.wbrs_core", cond: :eq, searchable: true, orderable: true},
      links:    {searchable: false}
    }
  end

  def data
    records.map do |record|
      {
          id:         record.id,
          tag:        record.tag,
          subdomain:  record.subdomain,
          domain:     record.domain,
          path:       record.path,
          status:     record.status,
          age:        record.age,
          customer:   record.customer,
          wbrs_core:  record.wbrs_score,
          links:
          content_tag(:div, class: 'toolbar-row') do
            concat(link_to "<button class='toolbar-button edit-button' alt='Edit complaint'></button>".html_safe, edit_escalations_webcat_complaint_path(record.id))
            concat(link_to "Delete", escalations_webcat_complaints_path(record.id), method: :delete, class: "btn btn-danger btn-xs", data: {confirm: 'Are you sure you want to annihilate this complaint?'} )
          end
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
