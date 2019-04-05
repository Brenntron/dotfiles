class FileRepDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    @view_columns ||= {
      name:               { data: :name, source: 'FileReputationDispute.file_rep_name', cond: :like },
      sha256_checksum:    { data: :sha256, source: 'FileReputationDispute.sha256_checksum', cond: :like },
      email:              { data: :email, source: 'FileReputationDispute.email', cond: :like },
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
    FileReputationDispute.all
  end

end
