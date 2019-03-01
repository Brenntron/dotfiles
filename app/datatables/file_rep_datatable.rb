class FileRepDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      sha256:             { data: :sha256, source: "FileRep.sha256", cond: :like },
      email:              { data: :email, source: "FileRep.email", cond: :like },
    }
  end

  def data
    records.map do |file_rep|
      {
        # example:
        # id: record.id,
        # name: record.name
        sha256:           file_rep.sha256,
        email:            file_rep.email,
        DT_RowId:         file_rep.id,
      }
    end
  end

  def get_raw_records
    # insert query here
    # User.all
    FileRep.all
  end

end
