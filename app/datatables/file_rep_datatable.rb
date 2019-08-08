class FileRepDatatable < AjaxDatatablesRails::ActiveRecord

  def initialize(params, initialize_params, user:)
    @user = user
    @search_string = initialize_params['value'] # Native datatables search string
    @search_type = initialize_params['search_type']
    @search_name = initialize_params['search_name']
    @search_conditions = initialize_params['search_conditions']
    super(params, {})
  end

  def view_columns
    @view_columns ||= {
      id:                 { data: :id, source: 'FileReputationDispute.id', cond: :like },
      created_at:         { data: :created_at, source: 'FileReputationDispute.created_at', cond: :date_range },
      updated_at:         { data: :updated_at, source: 'FileReputationDispute.updated_at', cond: :date_range },
      status:             { data: :status, source: 'FileReputationDispute.status', cond: :string_eq },
      resolution:         { data: :resolution, source: 'FileReputationDispute.resolution', cond: :string_eq },
      assigned:           { data: :assigned, source: 'FileReputationDispute.assigned', cond: :string_eq, orderable: false },
      file_name:          { data: :file_name, source: 'FileReputationDispute.file_name', cond: :like },
      file_size:          { data: :file_size, source: 'FileReputationDispute.file_size', searchable: false },
      sha256_hash:        { data: :sha256_hash, source: 'FileReputationDispute.sha256_hash', cond: :like },
      sample_type:        { data: :sample_type, source: 'FileReputationDispute.sample_type', cond: :string_eq },
      disposition:        { data: :disposition, source: 'FileReputationDispute.disposition', cond: :string_eq },
      disposition_suggested: { data: :disposition_suggested, source: 'FileReputationDispute.disposition_suggested', cond: :string_eq },
      description:        { data: :description, source: 'FileReputationDispute.description', cond: :string_eq},
      source:             { data: :source, source: 'FileReputationDispute.source', cond: :like },
      platform:           { data: :platform, source: 'FileReputationDispute.platform', cond: :like },
      sandbox_score:      { data: :sandbox_score, source: 'FileReputationDispute.sandbox_score', cond: :eq },
      sandbox_count:      { data: :sandbox_count, source: 'FileReputationDispute.sandbox_count', cond: :eq },
      sandbox_threshold:  { data: :sandbox_threshold, source: 'FileReputationDispute.sandbox_threshold', cond: :like },
      sandbox_under:      { data: :sandbox_under, source: 'FileReputationDispute.sandbox_under', cond: :like },
      sandbox_signer:     { data: :sandbox_signer, source: 'FileReputationDispute.sandbox_signer', cond: :like },
      detection_name:     { data: :detection_name, source: 'FileReputationDispute.detection_name', cond: :like },
      detection_last_set: { data: :detection_last_set, source: 'FileReputationDispute.detection_last_set', cond: :date_range },
      in_zoo:             { data: :in_zoo, source: 'FileReputationDispute.in_zoo', cond: :eq },
      threatgrid_score:   { data: :threatgrid_score, source: 'FileReputationDispute.threatgrid_score', cond: :like },
      threatgrid_threshold: { data: :threatgrid_threshold, source: 'FileReputationDispute.threatgrid_threshold', cond: :like },
      threatgrid_under:   { data: :threatgrid_under, source: 'FileReputationDispute.threatgrid_under', cond: :like },
      threatgrid_signer:  { data: :threatgrid_signer, source: 'FileReputationDispute.threatgrid_signer', cond: :like },
      reversing_labs_score: { data: :reversing_labs_score, source: 'FileReputationDispute.reversing_labs_score', searchable: false },
      reversing_labs_count: { data: :reversing_labs_count, source: 'FileReputationDispute.reversing_labs_count', searchable: false },
      reversing_labs_scanners: { data: :reversing_labs_scanners, source: 'FileReputationDispute.reversing_labs_scanners', searchable: false },
      reversing_labs_signer: { data: :reversing_labs_signer, source: 'FileReputationDispute.reversing_labs_signer', cond: :like },
      submitter_type: { data: :submitter_type, source: 'FileReputationDispute.submitter_type', cond: :like},
      customer_name:      { data: :customer_name, source: 'FileReputationDispute.customer_name', cond: :like, orderable: false },
      customer_email:     { data: :customer_email, source: 'FileReputationDispute.customer_email', cond: :like, orderable: false },
      customer_company_name: { data: :customer_company_name, source: 'FileReputationDispute.customer_company_name', cond: :like, orderable: false },
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

      rl_scanners =
          if file_rep.reversing_labs_raw
            rev_lab = FileReputationApi::ReversingLabs.new(sha256_hash: file_rep.sha256_hash,
                                                           raw_json: file_rep.reversing_labs_raw)
            rev_lab.scanners
          end

      {
          id:                           file_rep.id,
          created_at:                   file_rep.created_at,
          updated_at:                   file_rep.updated_at,
          status:                       file_rep.status,
          resolution:                   file_rep.resolution,
          assigned:                     file_rep.assigned&.cvs_username,
          file_name:                    file_rep.file_name,
          file_size:                    file_rep.bytes_to_kb,
          sha256_hash:                  file_rep.sha256_hash,
          sample_type:                  file_rep.sample_type,
          disposition:                  file_rep.disposition,
          disposition_suggested:        file_rep.disposition_suggested,
          description:                  file_rep.description,
          source:                       file_rep.source,
          platform:                     file_rep.platform,
          sandbox_score:                file_rep.sandbox_score,
          sandbox_threshold:            file_rep.sandbox_threshold,
          sandbox_under:                sandbox_under,
          sandbox_signer:               file_rep.sandbox_signer,
          detection_name:               file_rep.detection_name,
          detection_last_set:           file_rep.detection_last_set,
          in_zoo:                       file_rep.in_zoo?,
          threatgrid_score:             file_rep.threatgrid_score,
          threatgrid_threshold:         file_rep.threatgrid_threshold,
          threatgrid_under:             threatgrid_under,
          threatgrid_signer:            file_rep.threatgrid_signer,
          reversing_labs_score:         file_rep.reversing_labs_score,
          reversing_labs_count:         file_rep.reversing_labs_count,
          reversing_labs_scanners:      rl_scanners.to_json,
          reversing_labs_signer:        file_rep.reversing_labs_signer,
          submitter_type:               file_rep.submitter_type,
          customer_name:                file_rep.customer&.name,
          customer_email:               file_rep.customer&.email,
          customer_company_name:        file_rep.customer&.company&.name,
          DT_RowId:                     file_rep.id,
          current_user:                 @user.cvs_username
      }
    end
  end

  def get_raw_records
    FileReputationDispute.all
  end

  def filter_records(records)
    base_search =
        if @search_string.present?
          FileReputationDispute.robust_search('contains', params: { 'value' => @search_string }, user: @user)
        else
          super
        end

    if @search_type
      base_search.robust_search(@search_type, search_name: @search_name, params: @search_conditions, user: @user)
    else
      base_search
    end
  end

  def sort_records(records)
    case datatable.orders.first.column.sort_query
      when 'file_reputation_disputes.assigned'
        records.left_joins(:user).order("users.cvs_username #{datatable.orders.first.direction}")
      when 'file_reputation_disputes.customer_name'
        records.left_joins(:customer).order("customers.name #{datatable.orders.first.direction}")
      when 'file_reputation_disputes.customer_email'
        records.left_joins(:customer).order("customers.email #{datatable.orders.first.direction}")
      when 'file_reputation_disputes.customer_company_name'
        records.left_joins(customer: :company).order("companies.name #{datatable.orders.first.direction}")
      else
        super
    end
  end
end
