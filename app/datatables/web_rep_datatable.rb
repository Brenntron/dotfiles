class WebRepDatatable < AjaxDatatablesRails::ActiveRecord

  def initialize(params, initialize_params, user:)
    @search_string = params['search']&.fetch('value', nil) # Native datatables search string
    @search_type = params['search_type']
    @search_name = params['search_name']
    @search_conditions = params['search_conditions']
    @user = user
    super(params, {})
  end

  def view_columns
    @view_columns ||= {
      id: { source: 'Dispute.case_number', data: 'case_number' },
      assigned_to: { source: 'Dispute.assigned_to', data: 'assigned_to' },
      priority: { source: 'Dispute.priority', data: 'priority' },
      case_link: { source: 'Dispute.case_link', data: 'case_link' },
      status: { source: 'Dispute.status', data: 'status' },
      submission_type: { source: 'Dispute.submission_type', data: 'submission_type' },
      d_entry_preview: { source: 'Dispute.d_entry_preview', data: 'd_entry_preview' },
      case_opened_at: { source: 'Dispute.case_opened_at', data: 'case_opened_at' },
      case_age: { source: 'Dispute.case_age', data: 'case_age' },
      age_int: { source: 'Dispute.int_age', data: 'int_age' },
      status_comment: { source: 'Dispute.status_comment', data: 'status_comment' },
      dispute_resolution: { source: 'Dispute.dispute_resolution', data: 'dispute_resolution' },
      submitter_domain: { source: 'Dispute.org_domain', data: 'submitter_domain' },
      updated_at: { source: 'Dispute.updated_at', data: 'updated_at' },
      source: { source: 'Dispute.source', data: 'source' },
      submitter_type: { source: 'Dispute.submitter_type', data: 'submitter_type' },
      submitter_name: { source: 'Dispute.submitter_name', data: 'submitter_name' },
      submitter_email: { source: 'Dispute.submitter_email', data: 'submitter_email' },
      channel: { source: 'Dispute.channel', data: 'channel' }
    }
  end

  def data
    Dispute.to_data_packet(records, user: @user)
  end

  def get_raw_records
    Dispute.all
  end

  def filter_records(records)
    base_search =
      if  @search_string.present?
        Dispute.robust_search('contains', params: { 'value' => @search_string }, user: @user)
      else
        super
      end
    if @search_type
      base_search.robust_search(@search_type, search_name: @search_name, params: params, user: @user)
    else 
      base_search
    end
  end

  def sort_records(records)
    case datatable.orders.first.column.sort_query
    when 'disputes.assigned_to'
      vrt_user_id = User.where(email: 'vrt-incoming@sourcefire.com').first.id
      by_unassigned_first = Dispute.send(:sanitize_sql_array, [ 'case when user_id = %d then 0 else 1 end', vrt_user_id ])
      by_unassigned_last = Dispute.send(:sanitize_sql_array, [ 'case when user_id = %d then 1 else 0 end', vrt_user_id ])

      case datatable.orders.first.direction
      when 'DESC' then
        records.left_joins(:user).order(Arel.sql(by_unassigned_first)).order("users.cvs_username #{datatable.orders.first.direction}")
      when 'ASC' then
        records.left_joins(:user).order(Arel.sql(by_unassigned_last)).order("users.cvs_username #{datatable.orders.first.direction}")
      else
        super
      end
    when 'disputes.case_link'
      records.order("disputes.id #{datatable.orders.first.direction}")
    when 'disputes.d_entry_preview'
      records.joins(:dispute_entries).order("dispute_entries.uri #{datatable.orders.first.direction}")
    when 'disputes.case_age'
      direction = datatable.orders.first.direction == 'ASC' ? 'DESC' : 'ASC'
      records.order("disputes.case_opened_at #{direction}")
    when 'disputes.int_age'
      direction = datatable.orders.first.direction == 'ASC' ? 'DESC' : 'ASC'
      records.order("disputes.case_opened_at #{direction}")
    when 'disputes.status_comment'
      records.order("disputes.status_comment #{datatable.orders.first.direction}, disputes.resolution #{datatable.orders.first.direction}")
    when 'disputes.dispute_resolution'
      records.order("disputes.resolution #{datatable.orders.first.direction}")
    when 'disputes.source'
      records.order("disputes.ticket_source #{datatable.orders.first.direction}")
    when 'disputes.submitter_name'
      records.includes(:customer).order("customers.name #{datatable.orders.first.direction}")
    when 'disputes.submitter_email'
      records.includes(:customer).order("customers.email #{datatable.orders.first.direction}")
    else
      super
    end
  end
end
