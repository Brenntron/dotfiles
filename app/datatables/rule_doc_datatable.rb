class RuleDocDatatable < AjaxDatatablesRails::Base

  def_delegators :@view, :link_to, :edit_rule_doc_path, :rule_doc_path, :content_tag, :concat,:truncate

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
        sid:            {source: "Rule.sid", cond: :eq, searchable: true, orderable: true},
        summary:        {source: "RuleDoc.summary", cond: :like, searchable: true, orderable: false},
        details:        {source: "RuleDoc.details", cond: :like, searchable: true, orderable: false},
        bugs:           {source: "Bug.bugzilla_id", searchable: false},
        links:          {searchable: false},
    }
  end

  def data
    records.reject { |s| s.rule.sid.nil? }.map do |record|
      {
          sid:            record.rule.sid,
          summary:
              content_tag(:div) do
                concat(content_tag(:h4,record.summary,class:''))
                concat "\n"
                concat(content_tag(:span,truncate(record.rule.rule_content, :length => 100),class:'code-snippet'))
              end,
          details:        record.details,
          bugs:           record.rule.bugs.map{|b|b.bugzilla_id},
          links:
              content_tag(:div, class: 'toolbar-row') do
                concat(link_to "<button class='toolbar-button edit-button' alt='Edit Rule Doc'></button>".html_safe, edit_rule_doc_path(record.id))
                concat(link_to "<button class='toolbar-button delete-button' alt='Delete Rule Doc'></button>".html_safe, rule_doc_path(record.id), method: :delete, data: {confirm: 'Are you sure you want to annihilate this document?'} )
              end
      }
    end
  end

  private

  def get_raw_records
    RuleDoc.joins(:rule).where.not(rules: { sid: nil })
  end

  # ==== These methods represent the basic operations to perform on records
  # and feel free to override them

  # def filter_records(records)
  # end

   # def sort_records(records)
   #   binding.pry
   # end

  # def paginate_records(records)
  # end

  # ==== Insert 'presenter'-like methods below if necessary
end