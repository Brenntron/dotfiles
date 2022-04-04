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
      case_id:            {source: "SenderDomainReputationDispute.id", cond: :like},
      created_at:         {source: "SenderDomainReputationDispute.created_at", data: :created_at, cond: :date_range},
      age_int:            {source: "SenderDomainReputationDispute.age_int", data: :age_int, searchable: false, orderable: false},
      age:                {source: "SenderDomainReputationDispute.age", data: :age, searchable: false, orderable: false},
      status:             {source: "SenderDomainReputationDispute.status", data: :status, cond: :string_eq},
      resolution:         {source: "SenderDomainReputationDispute.resolution", data: :resolution, cond: :string_eq},
      source:             {source: "SenderDomainReputationDispute.source", data: :source, cond: :string_eq},
      platform:           {source: "SenderDomainReputationDispute.platform", data: :platform, cond: :string_eq},

      # subdomain:          {source: "ComplaintEntry.subdomain", data: :subdomain, cond: :like},
      # domain:             {source: "ComplaintEntry.domain", data: :domain, cond: :like},
      # ip_address:         {source: "ComplaintEntry.ip_address", data: :ip_address, cond: :like},
      # path:               {source: "ComplaintEntry.path", data: :path, cond: :like},
      # category:           {source: "ComplaintEntry.category", data: :category, cond: :string_eq},
      # suggested_disposition: {source: "ComplaintEntry.suggested_disposition", data: :suggested_disposition, cond: :string_eq},
      # suggested_category: {source: "ComplaintEntry.suggested_category", data: :suggested_category, cond: :string_eq},
      # suggested_category_count:       {source: "ComplaintEntry.suggested_category_count", data: :suggested_category_count, searchable: false, orderable: false},
      # wbrs_score:         {source: "ComplaintEntry.wbrs_score", data: :wbrs_score, cond: :eq},
      # customer_name:      {source: "ComplaintEntry.customer_name", data: :customer_name, cond: :like},
      # company_name:       {source: "ComplaintEntry.company_name", data: :company_name, cond: :like},
      # assigned_to:        {source: "ComplaintEntry.assigned_to", data: :assigned_to, cond: :date_range},
      # uri:                {source: "ComplaintEntry.uri", data: :uri, cond: :like},
      # resolution:         {source: "ComplaintEntry.resolution", data: :resolution, cond: :string_eq},
      # internal_comment:   {source: "ComplaintEntry.internal_comment", data: :internal_comment, cond: :like},
      # resolution_comment: {source: "ComplaintEntry.resolution_comment", data: :resolution_comment, cond: :like},
      # is_important:       {source: "ComplaintEntry.is_important", data: :is_important, searchable: false, orderable: false},
      # was_dismissed:      {source: "ComplaintEntry.was_dismissed", data: :was_dismissed, searchable: false, orderable: false},
      # viewable:           {source: "ComplaintEntry.viewable", data: :viewable, searchable: false, orderable: false},
      # complaint_id:       {source: "ComplaintEntry.complaint_id", data: :complaint_id, cond: :like},
      # tags:               {source: "ComplaintEntry.tags", data: :tags, searchable: false, orderable: false},
      # submitter_type:     {source: "ComplaintEntry.submitter_type", data: :submitter_type, cond: :string_eq},
      # customer_email:     {source: 'ComplaintEntry.customer_email', data: :customer_email, cond: :like, orderable: false },
      # description:        {source: "ComplaintEntry.description", data: :description, cond: :like},
      # platform:           {source: "ComplaintEntry.platform", data: :platform, cond: :like}
    }
  end


  def data
    records.map do |dispute|
      {
        case_id:        dispute.id,
        created_at:     dispute.created_at,
        age_int:        (Time.now - dispute.created_at).to_i,
        age:            SenderDomainReputationDispute.first_two_time_layers(time_ago_in_words(dispute.created_at, {scope: 'datetime.distance_in_words',include_seconds: false})),
        status:         dispute.status,
        resolution:     dispute.resolution,
        assignee:       dispute.user&.display_name,
        source:         dispute.source,
        platform:       dispute.platform&.public_name,
        dispute:        dispute.sender_domain_entry,
      }
    end
  end
  # def data
  #   records.map do |complaint_entry|
  #     complaint = complaint_entry.complaint
  #     suggested_dispositions = complaint_entry.suggested_disposition&.split(',')
  #
  #     {
  #       entry_id:         complaint_entry.id,
  #       created_at:       complaint_entry.created_at,
  #       age_int:          (Time.now - complaint_entry.created_at).to_i,
  #       age:              ComplaintEntry.first_two_time_layers(time_ago_in_words(complaint_entry.created_at, {scope: 'datetime.distance_in_words',include_seconds: false})),
  #       status:           complaint_entry.status,
  #       subdomain:        complaint_entry.subdomain,
  #       domain:           complaint_entry.domain,
  #       ip_address:       complaint_entry.ip_address,
  #       path:             complaint_entry.path,
  #       category:         complaint_entry.url_primary_category,
  #       suggested_disposition:        complaint_entry.suggested_disposition,
  #       suggested_category:           suggested_dispositions&.first,
  #       suggested_category_count:     suggested_dispositions ? suggested_dispositions.count : 0,
  #       wbrs_score:       complaint_entry.wbrs_score ? complaint_entry.wbrs_score.to_d.truncate(2).to_s : '',
  #       customer_name:    complaint_entry.customer_name,
  #       company_name:     complaint_entry.customer_company_name,
  #       customer_email:   complaint.customer&.email,
  #       complaint_source: complaint.ticket_source,
  #       assigned_to:      complaint_entry.user&.display_name,
  #
  #       uri:              complaint_entry.uri,
  #       resolution:       complaint_entry.resolution,
  #       internal_comment: complaint_entry.internal_comment,
  #       resolution_comment:           complaint_entry.resolution_comment,
  #       is_important:     complaint_entry.is_important,
  #       was_dismissed:    complaint_entry.was_dismissed?,
  #       viewable:         complaint_entry.viewable,
  #
  #       complaint_id:     complaint_entry.complaint_id,
  #       tags:             complaint.complaint_tags.map{|tag| tag&.name },
  #       submitter_type:   complaint.submitter_type,
  #       description:      complaint.description,
  #       uri_as_categorized: complaint_entry.uri_as_categorized,
  #       platform:         complaint_entry.determine_platform,
  #
  #       DT_RowId:         complaint_entry.id,
  #     }
  #   end
  # end

  # private

  def get_raw_records
    SenderDomainReputationDispute.all
  end

  def filter_records(records)
    base_search =
      if @search_string.present?
        # SenderDomainReputationDispute.robust_search('contains', params: { 'value' => @search_string }, user: @user)
      else
        super
      end

    if @search_type
      base_search.robust_search(@search_type, search_name: @search_name, params: @search_conditions, user: @user)
    else
      base_search
    end
  end

  # def sort_records(records)
  #   case datatable.orders.first.column.sort_query
  #   when 'complaint_entries.age_int'
  #     records.order("complaint_entries.created_at #{datatable.orders.first.direction}")
  #   when 'complaint_entries.submitter_type'
  #     records.left_joins(:complaint).order("complaints.submitter_type #{datatable.orders.first.direction}")
  #   when 'complaint_entries.company_name'
  #     records.left_joins(complaint: {customer: :company}).order("companies.name #{datatable.orders.first.direction}")
  #   when 'complaint_entries.customer_email'
  #     records.left_joins(complaint: :customer).order("customers.email #{datatable.orders.first.direction}")
  #   when 'complaint_entries.assigned_to'
  #     records.left_joins(:user).order("users.display_name #{datatable.orders.first.direction}")
  #   else
  #     super
  #   end
  # end
end
