class WebRepDatatable < AjaxDatatablesRails::ActiveRecord
# FileRepDatatable.new(params, initialize_params,user: current_user)

  def initialize(params, initialize_params, user:)
    @user = user
    @search_string = initialize_params['value'] # Native datatables search string
    @search_type = initialize_params['search_type']
    @search_name = initialize_params['search_name']
    @search_conditions = initialize_params['search_conditions']
    super(params, {})
  end

  def data
    Dispute.to_data_packet(records, user: @user).each_with_object([]) do |item, hash|
      item[:entries] = [DisputeEntry.first.attributes].to_json
      hash << item
    end
    # records.map do |dispute|
    #   {
    #     id: dispute.id,
    #     created_at: dispute.created_at
    #   }
    # end
  end

  def get_raw_records
    Dispute.all
  end

  def filter_records(records)
    # Dispute
    #   .robust_search(params[:search_type], search_name: params[:search_name], params: params, user: @user , reload: params[:reload])
    #   .includes(:user, :dispute_entries => [:dispute_rule_hits])
    Dispute.includes(:user, :dispute_entries => [:dispute_rule_hits])
  end

  def sort_records(records)

    # case datatable.orders.first.column.sort_query
    # when 'file_reputation_disputes.assigned'
    #   # When sorting by "assignee" (.user_id attribute on a FileReputationDispute), the 'vrtincoming' user should be considered
    #   # to be "last" in the list. CASE expressions are valid in a SQL ORDER BY, but ActiveRecord doesn't use placeholders in its'
    #   # ORDER BYs, so we define the orders here first, before using them on the `records.left_joins()` collections below.
    #   vrt_user_id = User.where(:cvs_username => "vrtincom").first.id
    #   by_unassigned_first = FileReputationDispute.send(:sanitize_sql_array, [ 'case when user_id = %d then 0 else 1 end', vrt_user_id ])
    #   by_unassigned_last = FileReputationDispute.send(:sanitize_sql_array, [ 'case when user_id = %d then 1 else 0 end', vrt_user_id ])

    #   case datatable.orders.first.direction
    #   when 'DESC'
    #     records.left_joins(:user).order(by_unassigned_first).order("users.cvs_username #{datatable.orders.first.direction}")
    #   when 'ASC'
    #     records.left_joins(:user).order(by_unassigned_last).order("users.cvs_username #{datatable.orders.first.direction}")
    #   else
    #     super # We shouldn't ever be in here but we have to do something if ever we are
    #   end
    # when 'file_reputation_disputes.customer_name'
    #   records.left_joins(:customer).order("customers.name #{datatable.orders.first.direction}")
    # when 'file_reputation_disputes.customer_email'
    #   records.left_joins(:customer).order("customers.email #{datatable.orders.first.direction}")
    # when 'file_reputation_disputes.customer_company_name'
    #   records.left_joins(customer: :company).order("companies.name #{datatable.orders.first.direction}")
    # else
    #   super
    # end
    Dispute.all
  end
end
