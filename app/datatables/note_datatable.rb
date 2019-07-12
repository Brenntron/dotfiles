class NoteDatatable < AjaxDatatablesRails::Base
  extend Forwardable

  def_delegators :@view, :link_to, :edit_admin_note_path, :admin_note_path, :content_tag, :concat

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:                 {source: "Note.id", cond: :eq, searchable: true, orderable: true},
      bug_id:             {source: "Note.bug_id", cond: :eq, searchable: true, orderable: true},
      comment:            {source: "Note.comment", cond: :like, searchable: true, orderable: true},
      note_type:          {source: "Note.note_type", cond: :like, searchable: true, orderable: true},
      author:             {source: "Note.author", cond: :like, searchable: true, orderable: true},
      notes_bugzilla_id:  {source: "Note.notes_bugzilla_id", cond: :eq, searchable: true, orderable: true},
      created_at:         {source: "Note.created_at", cond: :eq, searchable: true, orderable: true},
      updated_at:         {source: "Note.updated_at", cond: :eq, searchable: true, orderable: true},
      links:              {searchable: false}
    }
  end

  def data
    records.map do |record|
      {
        id:                 record.id,
        bug_id:             record.bug_id,
        comment:            record.comment,
        note_type:          record.note_type,
        author:             record.author,
        notes_bugzilla_id:  record.notes_bugzilla_id,
        created_at:         record.created_at,
        updated_at:         record.updated_at,
        links:
        content_tag(:div, class: 'toolbar-row') do
          concat(link_to "<button class='toolbar-button edit-button' alt='Edit Rule'></button>".html_safe, edit_admin_note_path(record.id))
          concat(link_to "Delete", admin_note_path(record.id), method: :delete, class: "btn btn-danger btn-xs", data: {confirm: 'Are you sure you want to annihilate this note?'} )
        end

      }
    end
  end

  private

  def get_raw_records
    Note.all
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
