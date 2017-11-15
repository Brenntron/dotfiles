class RuleDatatable < AjaxDatatablesRails::Base

  def_delegators :@view, :link_to, :edit_admin_rule_path, :related_admin_rule_path, :content_tag, :concat

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:             {source: "Rule.id", cond: :eq, searchable: true, orderable: true},
      sid:            {source: "Rule.sid", cond: :eq, searchable: true, orderable: true},
      message:        {source: "Rule.message", cond: :like, searchable: true, orderable: false},
      bug_count:      {source: "Rule.bugs.count", searchable: false, orderable: true},
      state:          {source: "Rule.state", cond: :like, searchable: true, orderable: true},
      edit_status:    {source: "Rule.edit_status", cond: :like, searchable: true, orderable: true},
      publish_status: {source: "Rule.publish_status", cond: :like, searchable: true, orderable: true},
      links:          {searchable: false}
    }
  end

  def data
    records.map do |record|
      {
        id:             record.id,
        sid:            record.sid,
        message:        record.message,
        bug_count:      record.bugs.count,
        state:          record.state,
        edit_status:    record.edit_status,
        publish_status: record.publish_status,
        links:
        content_tag(:div) do
          concat(link_to "Edit", edit_admin_rule_path(record.id), class: 'btn btn-default')
          concat " "
          concat(link_to "Related Data", related_admin_rule_path(record.id), class: 'btn btn-default')
        end
      }
    end
  end

  private

  def get_raw_records
    Rule.includes(:bugs)
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
