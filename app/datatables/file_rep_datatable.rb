class FileRepDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    @view_columns ||= {
      id:                 { data: :id, source: 'FileReputationDispute.id', cond: :like },
      created_at:         { data: :created_at, source: 'FileReputationDispute.created_at', cond: :date_range },
      updated_at:         { data: :updated_at, source: 'FileReputationDispute.updated_at', cond: :date_range },
      status:             { data: :status, source: 'FileReputationDispute.status', cond: :string_eq },
      resolution:         { data: :resolution, source: 'FileReputationDispute.resolution', cond: :string_eq },
      assigned:           { data: :assigned, source: 'FileReputationDispute.assigned', cond: :string_eq },
      file_name:          { data: :file_name, source: 'FileReputationDispute.file_name', cond: :like },
      file_size:          { data: :file_size, source: 'FileReputationDispute.file_size', searchable: false },
      sha256_hash:        { data: :sha256_hash, source: 'FileReputationDispute.sha256_hash', cond: :like },
      sample_type:        { data: :sample_type, source: 'FileReputationDispute.sample_type', cond: :string_eq },
      disposition:        { data: :disposition, source: 'FileReputationDispute.disposition', cond: :string_eq },
      disposition_suggested: { data: :disposition_suggested, source: 'FileReputationDispute.disposition_suggested', cond: :string_eq },
      source:             { data: :source, source: 'FileReputationDispute.source', cond: :like },
      platform:           { data: :platform, source: 'FileReputationDispute.platform', cond: :like },
      sandbox_score:      { data: :sandbox_score, source: 'FileReputationDispute.sandbox_score', cond: :like },
      sandbox_threshold:  { data: :sandbox_threshold, source: 'FileReputationDispute.sandbox_threshold', cond: :like },
      sandbox_under:      { data: :sandbox_under, source: 'FileReputationDispute.sandbox_under', cond: :like },
      sandbox_signer:     { data: :sandbox_signer, source: 'FileReputationDispute.sandbox_signer', cond: :like },
      detection_name:     { data: :detection_name, source: 'FileReputationDispute.detection_name', cond: :like },
      detection_created_at: { data: :detection_created_at, source: 'FileReputationDispute.detection_created_at', cond: :date_range },
      in_zoo:             { data: :in_zoo, source: 'FileReputationDispute.in_zoo', cond: :eq },
      threatgrid_score:   { data: :threatgrid_score, source: 'FileReputationDispute.threatgrid_score', cond: :like },
      threatgrid_threshold: { data: :threatgrid_threshold, source: 'FileReputationDispute.threatgrid_threshold', cond: :like },
      threatgrid_under:   { data: :threatgrid_under, source: 'FileReputationDispute.threatgrid_under', cond: :like },
      threatgrid_signer:  { data: :threatgrid_signer, source: 'FileReputationDispute.threatgrid_signer', cond: :like },
      reversing_labs_score: { data: :reversing_labs_score, source: 'FileReputationDispute.reversing_labs_score', cond: :like },
      reversing_labs_signer: { data: :reversing_labs_signer, source: 'FileReputationDispute.reversing_labs_signer', cond: :like },
      # customer_name:      { data: :customer_name, source: 'FileReputationDispute.customer_name', cond: :like },
      # customer_email:     { data: :customer_email, source: 'FileReputationDispute.customer_email', cond: :like },
      # customer_company_name: { data: :customer_company_name, source: 'FileReputationDispute.customer_company_name', cond: :like },
    }
  end

  def data
    records.map do |file_rep|
      sandbox_under =
          if file_rep.sandbox_score && file_rep.sandbox_threshold
            file_rep.sandbox_score < file_rep.sandbox_threshold
          end

      threatgrid_under =
          if file_rep.threatgrid_score && file_rep.threatgrid_threshold
            file_rep.threatgrid_score < file_rep.threatgrid_threshold
          end

      {
          id:                           file_rep.id,
          created_at:                   file_rep.created_at,
          updated_at:                   file_rep.updated_at,
          status:                       file_rep.status,
          resolution:                   file_rep.resolution,
          assigned:                     file_rep.assigned&.cvs_username,
          file_name:                    file_rep.file_name,
          file_size:                    file_rep.file_size,
          sha256_hash:                  file_rep.sha256_hash,
          sample_type:                  file_rep.sample_type,
          disposition:                  file_rep.disposition,
          disposition_suggested:        file_rep.disposition_suggested,
          source:                       file_rep.source,
          platform:                     file_rep.platform,
          sandbox_score:                file_rep.sandbox_score,
          sandbox_threshold:            file_rep.sandbox_threshold,
          sandbox_under:                sandbox_under,
          sandbox_signer:               file_rep.sandbox_signer,
          detection_name:               file_rep.detection_name,
          detection_created_at:         file_rep.detection_created_at,
          in_zoo:                       file_rep.in_zoo?,
          threatgrid_score:             file_rep.threatgrid_score,
          threatgrid_threshold:         file_rep.threatgrid_threshold,
          threatgrid_under:             threatgrid_under,
          threatgrid_signer:            file_rep.threatgrid_signer,
          reversing_labs_score:         file_rep.reversing_labs_score,
          reversing_labs_signer:        file_rep.reversing_labs_signer,
          customer_name:                file_rep.customer&.name,
          customer_email:               file_rep.customer&.email,
          customer_company_name:        file_rep.customer&.company&.name,
          DT_RowId:                     file_rep.id,
      }
    end
  end

  def get_raw_records
    FileReputationDispute.all
  end

end
