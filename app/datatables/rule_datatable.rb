class RuleDatatable < AjaxDatatablesRails::Base
  extend Forwardable

  def_delegators :@view, :link_to, :edit_admin_rule_path, :related_admin_rule_path, :content_tag, :concat

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:              {source: "Rule.id", cond: :eq, searchable: true, orderable: true},
      gid:             {source: "Rule.gid", cond: :eq, searchable: true, orderable: true},
      sid:             {source: "Rule.sid", cond: :eq, searchable: true, orderable: true},
      message:         {source: "Rule.message", cond: :like, searchable: true, orderable: false},
      bug_count:       {source: "Rule.bugs.count", searchable: false, orderable: true},
      state:           {source: "Rule.state", cond: :like, searchable: true, orderable: true},
      edit_status:     {source: "Rule.edit_status", cond: :like, searchable: true, orderable: true},
      publish_status:  {source: "Rule.publish_status", cond: :like, searchable: true, orderable: true},
      snort_doc_status:{source: "Rule.snort_doc_status", cond: :like, searchable: false, orderable: true},
      snort_on_off:    {source: "Rule.snort_on_off", cond: :like, searchable: false, orderable: true},
      links:           {searchable: false}
    }
  end

  def data
    records.map do |record|
      {
        id:              record.id,
        gid:             record.gid,
        sid:             record.sid,
        message:         record.message,
        bug_count:       record.bugs.count,
        state:           record.state,
        edit_status:     record.edit_status,
        publish_status:  record.publish_status,
        snort_doc_status:record.snort_doc_status,
        snort_on_off:    record.snort_on_off,
        links:
        content_tag(:div, class: 'toolbar-row') do
          concat(link_to "<button class='toolbar-button edit-button' alt='Edit Rule'></button>".html_safe, edit_admin_rule_path(record.id))
          concat(link_to "<button class='toolbar-button related-button' alt='Related Data'></button>".html_safe, related_admin_rule_path(record.id))
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
