# class FileReputationTicket < ApplicationRecord
class FileReputationDispute < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at, :user_id]

  belongs_to :customer, optional:true
  has_many :file_rep_comments
  belongs_to :assigned, class_name: 'User', foreign_key: :user_id, optional:true #TODO remove to use :user
  belongs_to :user, optional:true
  has_many :digital_signers
  has_many :file_rep_comments
  has_many :dispute_emails

  delegate :name, :email, :company, :company_name, :company_id, to: :customer, allow_nil: true, prefix: true

  STATUS_NEW                = 'NEW'
  STATUS_ASSIGNED           = 'ASSIGNED'
  STATUS_RESEARCHING        = 'RESEARCHING'
  STATUS_ESCALATED          = 'ESCALATED'
  STATUS_PENDING            = 'PENDING'
  STATUS_ONHOLD             = 'ONHOLD'
  STATUS_RESOLVED           = 'RESOLVED_CLOSED'
  STATUS_REOPENED           = 'RE-OPENED'
  STATUS_CUSTOMER_PENDING   = 'CUSTOMER_PENDING'
  STATUS_CUSTOMER_UPDATE    = 'CUSTOMER_UPDATE'

  DISPOSITION_UNSEEN        = 'unseen'
  DISPOSITION_UNKNOWN       = 'unknown'
  DISPOSITION_MALICIOUS     = 'malicious'
  DISPOSITION_COMMON        = 'common'
  DISPOSITION_CLEAN         = 'clean'

  SANDBOX_KEY_AC_REFRESH = 'AC-Refresh'
  SANDBOX_KEY_AC_FORM    = 'AC-Form'
  SANDBOX_KEY_TI_FORM    = 'TI-Form'
  SANDBOX_KEY_TI_API     = 'TI-API'

  SUBMITTER_TYPE_CUSTOMER = "CUSTOMER"
  SUBMITTER_TYPE_NONCUSTOMER = "NON-CUSTOMER"
  SUBMITTER_TYPE_INTERNAL = "INTERNAL"

  RESOLUTION_AUTORESOLVED               = 'Auto Resolved'
  RESOLUTION_DUPLICATE              = 'DUPLICATE'
  RESOLUTION_AUTORESOLVED_COMMENT       = <<~HEREDOC
    This ticket has been auto-resolved, suggested disposition and disposition already match.
  HEREDOC
  RESOLUTION_DUPLICATE_COMMENT          = <<~HEREDOC
    This ticket has been auto-resolved. A ticket with the same SHA256 hash already exists and is still open.
  HEREDOC

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  validates :status, :sha256_hash, :disposition_suggested, presence: true
  validates :sha256_hash, format: { with: /\A\h{64}\z/, message: "only 64 nibble (256 bit) hex code" }

  scope :by_customer, ->(customer_name: nil, customer_email: nil, company_name: nil) {
    result =
        case
        when company_name.present?
          joins(customer: :company)
        when customer_name.present? || customer_email.present?
          joins(:customer)
        else
          where({})
        end

    if customer_name.present?
      result = result.where('customers.name like :customer_name',
                            customer_name: "%#{sanitize_sql_like(customer_name)}%")
    end

    if customer_email.present?
      result = result.where('customers.email like :customer_email',
                            customer_email: "%#{sanitize_sql_like(customer_email)}%")
    end

    if company_name.present?
      result = result.where('companies.name like :company_name',
                            company_name: "%#{sanitize_sql_like(company_name)}%")
    end

    result
  }

  # defined so tests can stub to return false.
  def self.threaded?
    true
  end

  def malicious?
    self.disposition&.downcase == DISPOSITION_MALICIOUS.downcase
  end

  def suggested_malicious?
    self.disposition_suggested&.downcase == DISPOSITION_MALICIOUS.downcase
  end

  def clean?
    self.disposition&.downcase == DISPOSITION_CLEAN.downcase
  end

  def suggested_clean?
    self.disposition_suggested&.downcase == DISPOSITION_CLEAN.downcase
  end

  def is_assigned?
    (!self.user.blank? && self.user.email != 'vrt-incoming@sourcefire.com')
  end

  def compose_versioned_items

    versioned_items = [self]

    file_rep_comments.includes(:versions).map{ |dc| versioned_items << dc}

    versioned_items

  end

  def dispute_emails
    DisputeEmail.where(file_reputation_dispute_id: self.id)
  end

  def self.create_action(bugzilla_rest_session, sha256_hash, file_name, file_size, sample_type, disposition_suggested, source, platform, sha256_checksum)

    file_rep = FileReputationDispute.new

    summary = "New File Rep Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = %Q{
          File name: #{file_name};
          SHA256 hash: #{sha256_hash}
    }

    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'AMP Disputes',
        'summary' => summary,
        'version' => 'unspecified',
        'description' => full_description,
        'priority' => "P3",
        'classification' => 'unclassified',
    }

    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    customer = Customer.where(name: 'Dispute Analyst').first
    attributes = {
        id: bug_proxy.id,
        sha256_hash: sha256_hash,
        file_name: file_name,
        file_size: file_size,
        sample_type: sample_type,
        disposition_suggested: disposition_suggested,
        source: source,
        platform: platform,
        customer: customer,
        submitter_type: SUBMITTER_TYPE_INTERNAL
    }
    file_rep.assign_attributes(attributes)

    file_rep.update_scores

    if file_rep.save!
      file_rep
    else
      error_messages = file_rep.errors.full_messages.join('; ')
      render plain: "\"Error(s) creating file rep -- #{error_messages}\"", status: :internal_server_error
    end
  end

  def self.create_through_form(bugzilla_rest_session, sha256_hash, disposition_suggested, assignee_id)
    summary = "New File Rep Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = %Q{
          SHA256 hash: #{sha256_hash}
    }

    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'AMP Disputes',
        'summary' => summary,
        'version' => 'unspecified',
        'description' => full_description,
        'priority' => "P3",
        'classification' => 'unclassified',
    }

    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    file_rep = FileReputationDispute.new

    customer = Customer.where(name: 'Dispute Analyst').first

    attributes = {
        id: bug_proxy.id,
        sha256_hash: sha256_hash,
        disposition_suggested: disposition_suggested.downcase,
        user_id: assignee_id,
        sandbox_key: SANDBOX_KEY_AC_FORM,
        customer_id: customer.id,
        status: STATUS_ASSIGNED,
        submitter_type: SUBMITTER_TYPE_INTERNAL
    }

    file_rep.assign_attributes(attributes)

    file_rep.update_scores
    file_rep.populate_fields_from_rl

    # Check if the ticket can be resolved by matching suggested disposition and disposition (AMP)

    file_rep.auto_resolve_on_matching_disposition

    if file_rep.save!
      file_rep
    else
      error_messages = file_rep.errors.full_messages.join('; ')
      render plain: "\"Error(s) creating file rep -- #{error_messages}\"", status: :internal_server_error
    end
  end

  def populate_fields_from_rl
    api_response = FileReputationApi::ReversingLabs.get_creation_data(self.sha256_hash)

    self.update(file_size: api_response[:file_size], sample_type: api_response[:sample_type])
  end

  def self.save_named_search(search_name, params, user:, project_type:)
    NamedSearchCriterion.where(named_search_id: NamedSearch.where(user_id: user.id, name: search_name).ids).delete_all

    found_search = user.named_searches.where(name: search_name).first
    named_search = found_search || NamedSearch.create!(user: user, name: search_name, project_type: project_type)

    params.each do |field_name, value|
      case
      when value.blank?
        #do nothing
      when value.kind_of?(Hash) || value.kind_of?(ActionController::Parameters)
        value.each do |sub_field_name, sub_value|
          named_search.named_search_criteria.create(field_name: "#{field_name}~#{sub_field_name}", value: sub_value)
        end
      when 'search_type' == field_name
        #do nothing
      when 'search_name' == field_name
        #do nothing
      else
        named_search.named_search_criteria.create(field_name: field_name, value: value)
      end
    end
  end




  # omits fields with empty strings and nil as values
  # @param [Hash|ActionController::Parameters] fields input which may contain blank values
  # @return [Hash] A hash without blanks
  def self.non_blank_fields(fields)
    fields.to_h.reject{ |key, value| value.blank? }
  end

  # selects fields which match database field names from given parameters
  # @param [Hash|ActionController::Parameters] fields input which may contain blank values
  # @return [Hash] A hash with just this model's fields
  def self.matching_field(fields)
    fields.slice(*FileReputationDispute.column_names)
  end

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:)

    search_hash = non_blank_fields(params)
    sha256_hash = search_hash.delete('sha256_hash')
    file_name = search_hash.delete('file_name')
    threatgrid_range = search_hash.delete('threatgrid_score') || {}
    sandbox_range = search_hash.delete('sandbox_score') || {}
    created_at_range = search_hash.delete('created_at') || {}
    updated_at_range = search_hash.delete('updated_at') || {}
    dispute_fields = matching_field(search_hash)

    relation = where(dispute_fields)

    if sha256_hash.present?
      relation = relation.where('sha256_hash like :sha256_hash', sha256_hash: "%#{sanitize_sql_like(sha256_hash)}%")
    end

    if file_name.present?
      relation = relation.where('file_name like :file_name', file_name: "%#{sanitize_sql_like(file_name)}%")
    end

    if threatgrid_range['from'].present?
      relation = relation.where('threatgrid_score >= :threatgrid_from', threatgrid_from: threatgrid_range['from'].to_f)
    end

    if threatgrid_range['to'].present?
      relation = relation.where('threatgrid_score <= :threatgrid_to', threatgrid_to: threatgrid_range['to'].to_f)
    end

    if sandbox_range['from'].present?
      relation = relation.where('sandbox_score >= :sandbox_from', sandbox_from: sandbox_range['from'].to_f)
    end

    if sandbox_range['to'].present?
      relation = relation.where('sandbox_score <= :sandbox_to', sandbox_to: sandbox_range['to'].to_f)
    end

    if created_at_range['from'].present?
      relation = relation.where('created_at >= :created_at_from', created_at_from: created_at_range['from'])
    end

    if created_at_range['to'].present?
      created_at_to = created_at_range['to']
      relation = relation.where('created_at <= ADDDATE(:created_at_to, INTERVAL 1 DAY)', created_at_to: created_at_to)
    end

    if updated_at_range['from'].present?
      relation = relation.where('updated_at >= :updated_at_from', updated_at_from: updated_at_range['from'])
    end

    if updated_at_range['to'].present?
      updated_at_to = updated_at_range['to']
      relation = relation.where('updated_at <= ADDDATE(:updated_at_to, INTERVAL 1 DAY)', updated_at_to: updated_at_to)
    end

    if %w{customer_name customer_email company_name}.any? {|key_name| search_hash[key_name].present? }
      relation = relation.by_customer(customer_name: search_hash['customer_name'],
                                      customer_email: search_hash['customer_email'],
                                      company_name: search_hash['customer_company_name'])
    end

    # Save this search as a named search
    if params.present? && search_name.present?
      save_named_search(search_name, params, user: user, project_type: 'FileReputationDispute')
    end

    relation
  end

  # Searched based on saved search.
  # @param [String] search_name the name of the saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.named_search(search_name, user:)
    named_search = user.named_searches.where(name: search_name).first
    raise "No search named '#{search_name}' found." unless named_search
    search_params = named_search.named_search_criteria.inject({}) do |search_params, criterion|
      if /\A(?<super_name>[^~]*)~(?<sub_name>[^~]*)\z/ =~ criterion.field_name
        search_params[super_name] ||= {}
        search_params[super_name][sub_name] = criterion.value
      else
        search_params[criterion.field_name] = criterion.value
      end
      search_params
    end
    advanced_search(search_params, search_name: nil, user: user)
  end

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, user:)
    case search_name
    # when 'recently_viewed'
    #   joins(:dispute_peeks).where(dispute_peeks: {user_id: user.id})
    when 'my_open'
      where.not(status: STATUS_RESOLVED).where(user_id: user.id)
    when 'my_disputes'
      where(user_id: user.id)
    # when 'team_disputes'
    #   where(user_id: user.my_team)
    when 'unassigned'
      vrtincoming = User.vrtincoming
      where(user_id: [nil, vrtincoming]).where.not(status: STATUS_RESOLVED)
    when 'open'
      where.not(status: STATUS_RESOLVED)
    when 'closed'
      where(status: STATUS_RESOLVED)
    when 'all'
      where({})
    else
      raise "No search named '#{search_name}' known."
    end
  end

  # Searches many fields in the record for values containing a given value.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.contains_search(value)
    contains_fields =
        %w{file_reputation_disputes.id source platform file_name sha256_hash description detection_name sample_type}
    contains_where = contains_fields.map{|field| "#{field} like :pattern"}.join(' or ')

    customer_where = %w{name email}.map{|field| "customers.#{field} like :pattern"}.join(' or ')
    company_where = 'companies.name like :pattern'

    where_str = "#{contains_where} or #{customer_where} or #{company_where}"
    left_joins(customer: :company).where(where_str, pattern: "%#{value}%")
  end

  # Searches in a variety of ways.
  # advanced -- search by supplied field.
  # named -- call a saved search.
  # standard -- use a pre-defined search.
  # contains -- search many fields where supplied value is contained in the field.
  # nil -- all records.
  # @param [String] search_type variety of search
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name of saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.robust_search(search_type, search_name: nil, params: nil, user:)
    case search_type
    when 'advanced'
      advanced_search(params, search_name: search_name, user: user)
    when 'named'
      named_search(search_name, user: user)
    when 'standard'
      standard_search(search_name, user: user)
    when 'contains'
      contains_search(params['value'])
    else
      where({})
    end
  end

  def update_threadgrid_score
    if self.sha256_hash.present?
      threatgrid_response = Threatgrid::Search.query(self.sha256_hash)

      self.threatgrid_score = threatgrid_response[:threatgrid_score]
      self.threatgrid_private = threatgrid_response[:threatgrid_private]
      self.threatgrid_threshold = threatgrid_response[:threatgrid_threshold]
      save!
    end

  rescue => except
    Rails.logger.error("Error updating threatgrid score on id #{self.id} -- #{except.message}")
  end

  def update_ticode_certs
    certificates = FileReputationApi::ReversingLabs.certificates(self.sha256_hash)

    if certificates&.any?
      certificates.each do |certificate|
        digital_signers.create(issuer: certificate['issuer'],
                               subject: certificate['test'],
                               valid_from: certificate['valid_from'],
                               valid_to: certificate['valid_to'])
      end
    end
  end

  def update_reversing_labs_score
    rev_lab = FileReputationApi::ReversingLabs.lookup(self.sha256_hash)
    rev_lab.update_database
  rescue => except
    Rails.logger.error("Error updating reversing labs score on id #{self.id} -- #{except.message}")
  end

  def pdf?
    if self.file_name.present?
      /\.pdf$/i =~ self.file_name
    end
  end

  def update_sandbox_score(api_key_type: self.sandbox_key)
    sandbox_score = FileReputationApi::Sandbox.score(self.sha256_hash, api_key_type: api_key_type)
    sandbox_threshold = self.pdf? ? 90.0 : 61.0
    update!(sandbox_score: sandbox_score, sandbox_threshold: sandbox_threshold)
  rescue => except
    Rails.logger.error("Error updating sandbox score on id #{self.id} -- #{except.message}")
  end

  def update_amp_disposition
    detection = FileReputationApi::Detection.get_bulk(self.sha256_hash)

    update!(disposition: detection.disposition, detection_name: detection.name)

  rescue => except
    Rails.logger.error("Error updating amp disposition on #{self.id} -- #{except.message}")
  end

  def update_amp_detection_last_set
    detection_last_set = FileReputationApi::ElasticSearch.query(self.sha256_hash)
    if detection_last_set != 'No history to display' || self.detection_last_set.nil?
      update!(detection_last_set: detection_last_set, last_fetched: DateTime.now.utc)
    end
  rescue => except
    Rails.logger.error("Error updating amp detection last set on #{self.id} -- #{except.message}")
  end

  # Update scores when refreshing data on show page
  def update_sample_zoo
    zoo_response = FileReputationApi::SampleZoo.sha256_lookup(self.sha256_hash)
    begin
      attributes = FileReputationApi::SampleZoo.query_from_data(zoo_response)
      update!(attributes)
    rescue Exception => except
      Rails.logger.error("Error updating sample zoo flag for id #{self.id} -- #{except.message}")
    end
  end

  # Initialize all data as when creating a dispute record
  def update_superfecta
    update_threadgrid_score
    update_reversing_labs_score
    update_sandbox_score(api_key_type: SANDBOX_KEY_AC_REFRESH)
    update_sample_zoo
  end

  def update_scores
    update_amp_disposition
    update_amp_detection_last_set
    update_threadgrid_score
    update_ticode_certs
    update_reversing_labs_score
    update_sandbox_score
    update_sample_zoo
  end

  def ack_create(envelope_params, sender_params)
    sender_params[:addressee_id] = self.id
    sender_params[:addressee_status] = self.status
    Bridge::GenericAck.new(sender_params, addressee: envelope_params[:sender]).post
    true
  rescue => except
    Rails.logger.error("Error acknowledging File Reputation Dispute creation -- #{except.class.name} #{except.message}")
    false
  end

  #for support with incoming bridge messages from TI coming into messages_controller
  def self.process_bridge_payload(message_payload)
    new_dispute = nil
    customer_payload = {
        customer_name: message_payload[:payload][:customer_name],
        customer_email: message_payload[:payload][:customer_email],
        company_name: message_payload[:payload][:company_name]
    }

    user = User.where(cvs_username:"vrtincom").first
      ActiveRecord::Base.transaction do

        guest = Company.where(:name => "Guest").first
        opened_at = Time.now

        customer = Customer.file_rep_process_and_get_customer(customer_payload)

        bugzilla_rest_session = message_payload[:bugzilla_rest_session]

        summary = "New File Reputation Reputation Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

        full_description = <<~HEREDOC
          File name: #{message_payload[:payload][:file_name]}
          File Rep Sha: #{message_payload[:payload][:sha256]}
          

        HEREDOC

        bug_attrs = {
            'product' => 'Escalations Console',
            'component' => 'AMP Disputes',
            'summary' => summary,
            'version' => 'unspecified', #self.version,
            'description' => full_description,
            'priority' => 'Unspecified',
            'classification' => 'unclassified',
        }
        logger.debug "Creating bugzilla bug"

        bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

        logger.debug "Creating dispute"
        new_dispute = FileReputationDispute.new

        new_dispute.id = bug_proxy.id
        new_dispute.user_id = user.id
        new_dispute.sha256_hash = message_payload[:payload][:sha256]
        new_dispute.status = STATUS_NEW
        new_dispute.file_name = message_payload[:payload][:file_name]
        new_dispute.customer_id = customer.id
        new_dispute.file_size = message_payload[:payload][:file_size]
        new_dispute.sample_type = message_payload[:payload][:sample_type]
        new_dispute.disposition_suggested = message_payload[:payload][:disposition_suggested]
        new_dispute.source = message_payload[:payload][:source]
        new_dispute.platform = message_payload[:payload][:platform]
        new_dispute.sandbox_key = message_payload[:payload][:sandbox_key]
        new_dispute.ticket_source_key = message_payload[:source_key]
        new_dispute.description = message_payload[:payload][:summary_description]

        new_dispute.customer_id = customer&.id
        new_dispute.submitter_type = (new_dispute.customer.nil? || new_dispute.customer&.company_id == guest.id) ? SUBMITTER_TYPE_NONCUSTOMER : SUBMITTER_TYPE_CUSTOMER


        check_for_duplicate = FileReputationDispute.where(sha256_hash: message_payload[:payload][:sha256]).where.not(status: FileReputationDispute::STATUS_RESOLVED)
        if check_for_duplicate.any?
          auto_resolve_on_duplicate(new_dispute)
        else
          new_dispute.save
        end

      end #transaction

    # This is so the tests can stub out the `threaded?` method and test synchronously.
    if new_dispute
      if FileReputationDispute.threaded?
        Thread.new do
          new_dispute.update_scores
          new_dispute.auto_resolve_on_matching_disposition(from: 'TI')
        end
      else
        new_dispute.update_scores
        new_dispute.auto_resolve_on_matching_disposition(from: 'TI')
      end
    end

    new_dispute
  end

  def auto_resolve_on_matching_disposition(from: 'ACE')
      auto_resolved_boolean = false

      if (self.clean? && self.suggested_clean?) || (self.malicious? && self.suggested_malicious?)
        self.update(status: STATUS_RESOLVED, resolution: RESOLUTION_AUTORESOLVED, resolution_comment: RESOLUTION_AUTORESOLVED_COMMENT)

        auto_resolved_boolean = true
      end

      if from == 'TI'
        return_payload = {}
        return_payload[self.sha256_hash] = {
            resolution: self.resolution,
            resolution_comment: self.resolution_comment,
            status: self.status,
            sugg_type: self.disposition_suggested
        }

        conn = ::Bridge::FileRepCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: self.ticket_source_key, ac_id: self.id)
        conn.post(return_payload)
      end

      auto_resolved_boolean
  end

  def self.auto_resolve_on_duplicate(dispute)
    dispute.status = STATUS_RESOLVED
    dispute.resolution = RESOLUTION_DUPLICATE
    dispute.resolution_comment = RESOLUTION_DUPLICATE_COMMENT

    dispute.save

    return_payload = {}

    return_payload[dispute.sha256_hash] =
        {
        resolution: dispute.resolution,
        resolution_message: dispute.resolution_comment,
        status: dispute.status,
        sugg_type: dispute.disposition_suggested
        }

    conn = ::Bridge::FileRepCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: dispute.ticket_source_key, ac_id: dispute.id)
    conn.post(return_payload)
  end

  def self.process_status_changes(disputes, status, resolution = nil, comment = nil, current_user = nil)
    resolved_at = Time.now
    disputes.each do |dispute|
      dispute.status = status
      if resolution.present?
        dispute.resolution = resolution
        dispute.resolution_comment = comment
        dispute.case_closed_at = resolved_at
      else
        dispute.resolution = nil
        dispute.resolution_comment = nil
      end

      unless [STATUS_NEW, STATUS_ASSIGNED].include?(dispute.status)
        dispute.user_id = current_user.id unless dispute.is_assigned?
      end

      dispute.save!

      if comment.present?
        FileRepComment.create(:user_id => current_user.id, :comment => comment, :file_reputation_dispute_id => dispute.id)
      end

      dispute.reload

      conn = ::Bridge::FileRepUpdateStatusEvent.new(addressee: "talos-intelligence")
      conn.post(dispute, source_authority: "talos-intelligence", source_key: dispute.ticket_source_key)

    end
  end

  def self.take_tickets(dispute_ids, user:)
    FileReputationDispute.transaction do
      unless 0 == FileReputationDispute.where(id: dispute_ids).where.not(user_id: User.vrtincoming.id).count
        raise 'This ticket is already assigned'
      end
      FileReputationDispute.assign(dispute_ids, user: user)
    end
  end


  def self.assign(dispute_ids, user:)
    disputes_ary = []
    user_id = user.kind_of?(User) ? user.id : user

    FileReputationDispute.transaction do
      disputes = FileReputationDispute.where(id: dispute_ids)
      disputes_ary = disputes.all.to_a

      disputes.update_all(user_id: user_id, status: FileReputationDispute::STATUS_ASSIGNED)
    end

    disputes_ary
  end

  def return_dispute
    update!(user_id: User.vrtincoming.id, status: FileReputationDispute::STATUS_NEW)
  end

  def bytes_to_kb
    if file_size.present?
      self.file_size/1024
    end
  end

  def self.export_xlsx(search_params_json, current_user:)
    fields = %w{id status resolution file_name sha256_hash file_size sample_type
                disposition detection_name detection_last_set
                in_zoo sandbox_score threatgrid_score reversing_labs_score reversing_labs_count
                disposition_suggested created_at submitter_type
                customer_name company_name customer_email user_id}
    search_params = JSON.parse(search_params_json)

    file_rep_disputes = robust_search(search_params['search_type'],
                                      search_name: search_params['search_name'],
                                      params: search_params['search_conditions'],
                                      user: current_user)

    if search_params['selected_cases'].length > 0
      file_rep_disputes = file_rep_disputes.where(id: search_params['selected_cases'])
    end

    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    %w{Case\ ID Status Resolution File\ Name SHA256 File\ Size Sample\ Type
       AMP\ Disposition AMP\ Detection\ Name AMP\ Detection\ Created
       In\ Zoo Sandbox\ Score TG\ Score Reversing\ Labs\ Hits RL\ Scanners\ Total
       Suggested\ Disposition Time\ Submitted Submitter\ Type
       Customer\ Name Customer\ Organization Customer\ email Assignee}.each_with_index do |field_name, col_index|
      worksheet.add_cell(0, col_index, field_name)
      worksheet.sheet_data[0][col_index].change_font_bold(true)
    end

    file_rep_disputes.each_with_index do |fr_dispute, row_index|
      fields.each_with_index do |field_name, col_index|

        cell_data =
            case field_name
            when 'detection_last_set'
              fr_dispute.detection_last_set&.utc&.iso8601
            when 'in_zoo'
              fr_dispute.in_zoo? ? 'True' : 'False'
            when 'created_at'
              fr_dispute.created_at.utc.iso8601
            when 'customer_name'
              fr_dispute.customer_name
            when 'customer_email'
              fr_dispute.customer_email
            when 'company_name'
              fr_dispute.customer_company_name
            when 'user_id'
              fr_dispute.user&.cvs_username
            else
              fr_dispute.attributes[field_name]
            end

        worksheet.add_cell(row_index + 1, col_index, cell_data)
      end
    end

    workbook
  end
end