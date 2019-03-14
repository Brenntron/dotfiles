class FileRepDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    @view_columns ||= {
      name:               { data: :name, source: 'FileRep.file_rep_name', cond: :like },
      sha256_checksum:    { data: :sha256, source: 'FileRep.sha256_checksum', cond: :like },
      email:              { data: :email, source: 'FileRep.email', cond: :like },
    }
  end

  def data
    records.map do |file_rep|
      {
        name:             file_rep.file_rep_name,
        sha256_checksum:  file_rep.sha256_checksum,
        email:            file_rep.email,
        DT_RowId:         file_rep.id,
      }
    end
  end

  def get_raw_records
    FileRep.all
  end

end
