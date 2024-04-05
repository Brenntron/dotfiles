class SdrDisputeDatatable < AjaxDatatablesRails::ActiveRecord

  def initialize(params, initialize_params, user:)
    @user = user
    @search_string = initialize_params['value'] # Native datatables search string
    @search_type = initialize_params['search_type']
    @search_name = initialize_params['search_name']
    @search_conditions = initialize_params['search_conditions']
    super(params, {})
  end

  # TODO: add  current rep and rules (blocked by schema right now)
  def view_columns
    @view_columns ||= {
      case_id:                  { source: "SenderDomainReputationDispute.id", cond: :like },
      created_at:               { source: "SenderDomainReputationDispute.created_at", data: :created_at, cond: :date_range },
      age_int:                  { source: "SenderDomainReputationDispute.age_int", data: :age_int, searchable: false, orderable: false },
      age:                      { source: "SenderDomainReputationDispute.age", data: :age, searchable: false, orderable: false },
      status:                   { source: "SenderDomainReputationDispute.status", data: :status, cond: :string_eq },
      resolution:               { source: "SenderDomainReputationDispute.resolution", data: :resolution, cond: :string_eq },
      source:                   { source: "SenderDomainReputationDispute.source", data: :source, cond: :string_eq },
      priority:                 { source: "SenderDomainReputationDispute.priority", data: :priority, cond: :like },
      suggested_disposition:    { source: "SenderDomainReputationDispute.suggested_disposition", data: :suggested_disposition, cond: :like },
      assignee:                 { source: "User.cvs_username", data: :assignee, cond: :like },
      platform:                 { source: "Platform.public_name", data: :platform, cond: :string_eq },
      dispute:                  { source: "SenderDomainReputationDispute.sender_domain_entry", data: :dispute, cond: :like },
      submitter_type:           { source: "SenderDomainReputationDispute.submitter_type", data: :submitter_type, cond: :string_eq },
      contact_name:             { source: "Customer.name", data: :contact_name, cond: :like },
      contact_email:            { source: "Customer.email", data: :contact_email, cond: :like },
      submitter_org:            { source: "Company.name", data: :contact_email, cond: :like },
    }
  end


  def data
    records.map do |dispute|
      {
        case_id:                dispute.id,
        created_at:             dispute.created_at,
        age_int:                (Time.now - dispute.created_at).to_i,
        age:                    SenderDomainReputationDispute.humanize_secs(Time.now - dispute.created_at),
        status:                 dispute.status,
        resolution:             dispute.resolution,
        assignee:               dispute.user&.is_inactive? ? "#{dispute.user&.cvs_username} (inactive)": dispute.user&.cvs_username,
        source:                 dispute.source || 'Internal',
        priority:               dispute.priority,
        suggested_disposition:  dispute.suggested_disposition,
        platform:               dispute.platform&.public_name,
        dispute:                dispute.sender_domain_entry,
        submitter_type:         dispute.submitter_type,
        contact_name:           dispute.customer&.name,
        contact_email:          dispute.customer&.email,
        submitter_org:          dispute.customer&.company&.name,
        current_user:           @user.cvs_username,
      }
    end
  end

  def get_raw_records
    SenderDomainReputationDispute.includes({ customer: :company }, :platform, :user)
  end

  def filter_records(records)
    base_search =
      if @search_string.present?
        SenderDomainReputationDispute.robust_search('contains', params: { 'value' => @search_string }, user: @user)
      else
        super
      end

    if @search_type
      base_search.robust_search(@search_type, search_name: @search_name, params: @search_conditions, user: @user)
    else
      base_search
    end
  end
end
