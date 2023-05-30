class SenderDomainReputationDispute < ApplicationRecord
  class SdrDisputeError < StandardError; end

  has_paper_trail on: [:update], ignore: [:updated_at, :user_id]

  belongs_to :customer, optional: true
  belongs_to :user, optional: true
  belongs_to :platform, optional: true

  has_many :sender_domain_reputation_dispute_attachments
  has_many :dispute_emails
  has_many :sender_domain_reputation_dispute_comments

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  validates_length_of :resolution_comment, maximum: 2000, allow_blank: true

  NEW = 'NEW'
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
  STATUS_PROCESSING         = 'PROCESSING'


  SUBMITTER_TYPE_CUSTOMER = "CUSTOMER"
  SUBMITTER_TYPE_NONCUSTOMER = "NON-CUSTOMER"
  SUBMITTER_TYPE_INTERNAL = "INTERNAL"

  RESOLUTION_DUPLICATE = "DUPLICATE"

  EXPORT_FIELD_NAMES = {
    'id' => 'Case ID',
    'domain_name' => 'Domain Name',
    'status' => 'Status',
    'resolution' => 'Resolution',
    'resolution_comment' => 'Resolution Comment',
    'platform' => 'Platform',
    'source' => 'Source',
    'suggested_disposition' => 'Suggested Dispostion',
    'submitter_type' => 'Submitter Type',
    'description' => 'Description',
    'user_id' => 'Assignee',
    'created_at' => 'Time Submitted',
    'customer_name' => 'Customer Name',
    'company_name' => 'Company Name',
    'customer_email' => 'Customer Email'
}.freeze

  def self.process_bridge_payload(message_payload)
    customer_payload = {
        customer_name: message_payload[:payload][:customer_name],
        customer_email: message_payload[:payload][:customer_email],
        company_name: message_payload[:payload][:company_name]
    }

    #check to see if ticket already exists in database to prevent accidental dupes
    record_exists = SenderDomainReputationDispute.where(:ticket_source_key => message_payload[:source_key]).first

    if record_exists.present?
      record_exists.send_created_ack
      return record_exists
    end

    begin

      is_duplicate = false
      user = User.where(cvs_username:"vrtincom").first

      guest = Company.where(:name => "Guest").first
      opened_at = Time.now

      customer = Customer.file_rep_process_and_get_customer(customer_payload)

      bugzilla_rest_session = message_payload[:bugzilla_rest_session]
      message_payload.delete(:bugzilla_rest_session)
      summary = "New Sender Domain Reputation Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

      full_description = <<~HEREDOC
        SDR Dispute entry: #{message_payload[:payload][:sender_domain_entry]}
        SDR Dispute Problem Summary: #{message_payload[:payload][:problem_summary]}


      HEREDOC


      bug_attrs = {
          'product' => 'Escalations Console',
          'component' => 'SDR Disputes',
          'summary' => summary,
          'version' => 'unspecified', #self.version,
          'description' => full_description,
          'priority' => 'Unspecified',
          'classification' => 'unclassified',
      }
      logger.debug "Creating bugzilla bug"

      bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

      logger.debug "Creating dispute"
      new_dispute = SenderDomainReputationDispute.new

      if message_payload[:payload][:platform].present?
        platform = Platform.find(message_payload[:payload][:platform].to_i) rescue nil
      end

      new_dispute.id = bug_proxy.id
      new_dispute.bridge_packet = message_payload.to_json
      new_dispute.meta_data = message_payload[:payload][:meta_data] if message_payload[:payload][:meta_data].present?
      new_dispute.user_id = user.id
      new_dispute.sender_domain_entry = message_payload[:payload][:sender_domain_entry]
      new_dispute.status = STATUS_NEW

      new_dispute.platform_id = platform.id unless platform.blank?
      new_dispute.product_version = message_payload[:payload][:product_version] unless message_payload[:payload][:product_version].blank?

      new_dispute.suggested_disposition = message_payload[:payload][:suggested_disposition]
      new_dispute.source = message_payload["source"].blank? ? "talos-intelligence" : message_payload["source"]


      new_dispute.ticket_source_key = message_payload[:source_key]
      new_dispute.description = message_payload[:payload][:summary_description]
      new_dispute.customer_id = customer&.id
      new_dispute.submitter_type = (new_dispute.customer.nil? || new_dispute.customer&.company_id == guest.id) ? SUBMITTER_TYPE_NONCUSTOMER : SUBMITTER_TYPE_CUSTOMER
      if message_payload[:payload][:api_customer].present? && message_payload[:payload][:api_customer] == true
        new_dispute.submitter_type = SUBMITTER_TYPE_CUSTOMER
      end

      if new_dispute.submitter_type == SUBMITTER_TYPE_CUSTOMER
        new_dispute.priority = "P3"
      else
        new_dispute.priority = "P4"
      end

      #TODO: DO DUPLICATE CHECKING HERE
      #check_for_duplicate = SenderDomainReputationDispute.where(sender_domain_entry: message_payload[:payload][:sender_domain_entry]).where.not(status: SenderDomainReputationDispute::STATUS_RESOLVED)
      #if check_for_duplicate.any?
      #  auto_resolve_on_duplicate(new_dispute)
      #else
      new_dispute.save
      #end

      new_dispute.get_and_save_beaker_data
      #retry
      if new_dispute.beaker_info.blank?
        new_dispute.get_and_save_beaker_data
      end

      assemble_initial_email(new_dispute, message_payload[:payload])

      if message_payload["attachments"].present?
        message_payload["attachments"].each do |dispute_attachment|
          SenderDomainReputationDisputeAttachment.build_and_push_to_bugzilla(dispute_attachment, new_dispute)
        end
        #retry for sometimes it gets weird
        if new_dispute.sender_domain_reputation_dispute_attachments.size != message_payload["attachments"].size
          new_dispute.sender_domain_reputation_dispute_attachments.destroy_all
          new_dispute.reload
          message_payload["attachments"].each do |dispute_attachment|
            SenderDomainReputationDisputeAttachment.build_and_push_to_bugzilla(dispute_attachment, new_dispute)
          end
        end


        new_dispute.reload
      end

      if message_payload["attachments"].present? && message_payload["attachments"].size != new_dispute.sender_domain_reputation_dispute_attachments.size
        raise "attachments failed to save"
      end

      ###seperating this to try to prevent cases where email_header_data is "nil" in retrieve_attachments_beaker_data even though there is data.
      if new_dispute.sender_domain_reputation_dispute_attachments.present?
        new_dispute.parse_all_email_file_headers
      end
      new_dispute.reload
      if new_dispute.sender_domain_reputation_dispute_attachments.present?
        new_dispute.retrieve_attachments_beaker_data
      end

      new_dispute.send_created_ack

      new_dispute

    rescue => e

      new_dispute = SenderDomainReputationDispute.where(:ticket_source_key => message_payload[:source_key]).first
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")

      if new_dispute.present?
        new_dispute.reload
        new_dispute.sender_domain_reputation_dispute_attachments.destroy
        new_dispute.destroy
      end
      if message_payload["source_key"].present?
        begin
          conn = ::Bridge::SdrDisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
          conn.post
        rescue
          conn = Bridge::SdrDisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
          conn.post
        end
      end
      return nil
    end
    if new_dispute.present?
      new_dispute.reload
    end
    if new_dispute.present? && new_dispute.sender_domain_reputation_dispute_attachments.present? && new_dispute.sender_domain_reputation_dispute_attachments.size != message_payload["attachments"].size
      new_dispute.sender_domain_reputation_dispute_attachments.destroy_all
      new_dispute.destroy
      conn = ::Bridge::SdrDisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
      conn.post
      return nil
    end

    ### redundant for verification
    if new_dispute.present?
      new_dispute.send_created_ack
    end
  end

  def self.find_customer(customer)
    email = customer.split(':').last
    Customer.find_by_email(email)
  end


  def self.validate_entry(entry)
    valid_email = !(URI::MailTo::EMAIL_REGEXP =~ entry).nil?
    valid_domain = PublicSuffix.valid?(entry, default_rule: nil, ignore_private: true)
    has_no_html = ActionView::Base.full_sanitizer.sanitize(entry) == entry
    raise SdrDisputeError, "This is an invalid entry" unless has_no_html && (valid_email || valid_domain)
  end

  def self.create_action(bugzilla_rest_session, sender_domain_entry, priority, suggested_disposition, platform, customer, description, user_id, status=NEW)
    validate_entry(sender_domain_entry)
    extracted_domain = Mail::Address.new(sender_domain_entry).domain
    sender_domain_entry = extracted_domain.nil? ? sender_domain_entry : extracted_domain

    summary = "New Senders Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    # Does a description need to go in here and be in the form?
    full_description = %Q{
          IPs/URIs: #{sender_domain_entry}
    }

    bug_attrs = {
      'product' => 'Escalations Console',
      'component' => 'IP/Domain',
      'summary' => summary,
      'version' => 'unspecified',
      'description' => full_description,
      'priority' => priority,
      'classification' => 'unclassified',
    }

    platform_record = Platform.find_by_public_name(platform) if platform
    cust = find_customer(customer) if customer
    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    new_dispute = SenderDomainReputationDispute.create!(id: bug_proxy.id,
                                  user_id: user_id,
                                  sender_domain_entry: sender_domain_entry,
                                  priority: priority,
                                  suggested_disposition: suggested_disposition,
                                  platform_id: platform_record&.id,
                                  submitter_type: 'Internal',
                                  status: status,
                                  customer_id: cust&.id,
                                  description: description)

    new_dispute
  end

  def self.auto_resolve_on_duplicate(dispute)
    dispute.status = STATUS_RESOLVED
    dispute.resolution = RESOLUTION_DUPLICATE
    dispute.resolution_comment = RESOLUTION_DUPLICATE_COMMENT

    dispute.save

    dispute.send_created_ack

  end

  def retrieve_attachments_beaker_data
    self.sender_domain_reputation_dispute_attachments.each do |attachment|
      if attachment.email_header_data.present?
        attachment.retrieve_beaker_data_and_save
        if attachment.beaker_info.blank?
          attachment.retrieve_beaker_data_and_save
        end
      end
    end
  end

  def send_created_ack
    return_payload = {}
    return_payload[self.sender_domain_entry] = {
        resolution: self.resolution,
        resolution_comment: self.resolution_comment,
        status: self.status,
        sugg_type: self.suggested_disposition
    }
    ##Note: I don't know why this works, but in dev when a flood of tickets are incoming sometimes would get this error:
    # Unable to autoload constant Bridge::BaseMessage, expected /analyst-console-escalations/app/models/bridge/base_message.rb to define it (LoadError)
    # having Bridge as a retry of ::Bridge *seems* to work.  i suspect there's a deeper problem here but not prepared for that rabbit hole
    begin
      conn = ::Bridge::SdrDisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: self.ticket_source_key, ac_id: self.id, ticket_status: self.status)
      conn.post(return_payload)
    rescue
      conn = Bridge::SdrDisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: self.ticket_source_key, ac_id: self.id, ticket_status: self.status)
      conn.post(return_payload)
    end
  end


  def send_failed_ack(source_key)

    conn = ::Bridge::SdrDisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: source_key)
    conn.post
  end

  def return_dispute
    update!(user_id: User.vrtincoming.id, status: STATUS_NEW)
    Bridge::SdrDisputeUpdateStatusEvent.new.post(self.reload, :source_key => self.ticket_source_key)
  end

  def case_id_str
    '%010i' % id
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

      SenderDomainReputationDisputeComment.create!(user_id: current_user.id,
                                                   comment: comment,
                                                   sender_domain_reputation_dispute_id: dispute.id)

      dispute.reload

      Bridge::SdrDisputeUpdateStatusEvent.new.post(dispute, :source_key => dispute.ticket_source_key)

    end
  end

  def self.take_tickets(dispute_ids, user:)
    SenderDomainReputationDispute.transaction do
      if SenderDomainReputationDispute.where(id: dispute_ids).where.not(user_id: User.vrtincoming.id).present?
        raise 'This ticket is already assigned'
      end
      SenderDomainReputationDispute.assign(dispute_ids, user: user)
    end
  end

  def self.assign(dispute_ids, user:)
    disputes_ary = []
    user_id = user.kind_of?(User) ? user.id : user
    assigned_at = Time.now
    SenderDomainReputationDispute.transaction do
      disputes = SenderDomainReputationDispute.where(id: dispute_ids).where.not(status: STATUS_RESOLVED)
      disputes_ary = disputes.to_a

      disputes.update_all(user_id: user_id, status: STATUS_ASSIGNED, case_assigned_at: assigned_at)
      disputes.each do |dispute|
        message = Bridge::SdrDisputeUpdateStatusEvent.new
        message.post(dispute, :source_key => dispute.ticket_source_key)
      end
    end
    disputes_ary
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

  # Searches many fields in the record for values containing a given value.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.contains_search(value)
    sdr_dispute_fields = %w[id status resolution source sender_domain_entry submitter_type]
    sdr_dispute_where = sdr_dispute_fields.map do |field|
      "sender_domain_reputation_disputes.#{field} like :pattern"
    end.join(' or ')

    user_where = "users.display_name like :pattern"
    platform_where = "platforms.public_name like :pattern"
    company_where = "companies.name like :pattern"
    customer_where = %w[email name].map { |field| "customers.#{field} like :pattern" }.join(' or ')

    where_str = [sdr_dispute_where, user_where, platform_where, company_where, company_where, customer_where].join(' or ')
    left_joins({ customer: :company }, :platform, :user).where(where_str, pattern: "%#{value}%")
  end

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:, reload: false)
    dispute_params = non_blank_fields(params)
    dispute_fields = matching_fields(dispute_params) # to store attributes related to SenderDomainReputationDispute only

    dispute_fields['id'] = dispute_fields['id'].split(/[\s,]+/) if dispute_fields['id'].present?

    if dispute_params['case_owner'].present?
      user = User.find_by(cvs_username: dispute_params.delete('case_owner'))
      dispute_fields['user_id'] = user.id
    end

    relation = where(dispute_fields)

    if dispute_params['submitted_newer'].present?
      relation =
        relation.where('created_at >= :submitted_newer', submitted_newer: dispute_params['submitted_newer'])
    end

    if dispute_params['submitted_older'].present?
      if dispute_params['submitted_older'].kind_of?(Date)
        relation =
          relation.where('created_at < :submitted_older', submitted_older: (dispute_params['submitted_older']) + 1)
      elsif dispute_params['submitted_older'].kind_of?(String)
        relation =
          relation.where('created_at < :submitted_older', submitted_older: Date.parse(dispute_params['submitted_older']) + 1)
      end
    end

    if dispute_params['age_newer'].present?
      seconds_ago = age_to_seconds(dispute_params['age_newer'])
      if seconds_ago != 0
        age_newer_cutoff = Time.now - seconds_ago
        relation =
          relation.where('created_at >= :submitted_newer', submitted_newer: age_newer_cutoff)
      end
    end

    if dispute_params['age_older'].present?
      seconds_ago = age_to_seconds(dispute_params['age_older'])
      if seconds_ago != 0
        age_older_cutoff = Time.now - seconds_ago
        relation =
          relation.where('created_at < :submitted_older', submitted_older: age_older_cutoff)
      end
    end

    if dispute_params['platform_ids'].present?
      ids = dispute_params['platform_ids'].split(',').map(&:to_i)
      relation = relation.joins(:platform).where('sender_domain_reputation_disputes.platform_id in (:ids)', ids: ids)
    end

    company_name = nil
    customer_params = dispute_params.slice(*%w[customer_name customer_email company_name]).select { |_, value| value.present? }

    if customer_params.any?
      if customer_params['company_name'].present?
        company_name = customer_params.delete('company_name')
        relation = relation.joins(customer: :company)
      else
        relation = relation.joins(:customer)
      end

      customer_params['name'] = customer_params.delete('customer_name') if customer_params['customer_name'].present?
      customer_params['email'] = customer_params.delete('customer_email') if customer_params['customer_email'].present?
      customer_where = customer_params
      if company_name.present?
        customer_where = customer_where.merge(companies: { name: company_name } )
      end
      relation = relation.where(customers: customer_where)
    end

    # Save this search as a named search
    if params.present? && search_name.present? && reload == false
      save_named_search(search_name, params, user: user, project_type: 'SDR')
    end
    relation
  end

  # Searches specific to quick generic button filters.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, user:)
    case search_name
    when 'my_open'
      where.not(status: STATUS_RESOLVED).where(user_id: user.id)
    when 'my_disputes'
      where(user_id: user.id)
    when 'unassigned'
      vrtincoming = User.vrtincoming
      where(user_id: [nil, vrtincoming]).where.not(status: STATUS_RESOLVED)
    when 'open'
      where.not(status: STATUS_RESOLVED)
    when 'team_disputes'
      where(user_id: user.my_team)
    when 'closed'
      where(status: STATUS_RESOLVED)
    when 'all'
      all
    else
      raise "No search named '#{search_name}' known."
    end
  end

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

  # selects fields which match database field names from given parameters
  # @param [Hash|ActionController::Parameters] fields input which may contain blank values
  # @return [Hash] A hash with just this model's fields
  def self.matching_fields(fields)
    fields.slice(*column_names)
  end

  def self.age_to_seconds(age_str)
    days =
      if /(?<days_str>\d+)[Dd]/ =~ age_str
        days_str.to_i
      else
        0
      end
    hours =
      if /(?<hours_str>\d+)[Hh]/ =~ age_str
        hours_str.to_i
      else
        0
      end
    (days * 24 + hours) * 3600
  end

  # omits fields with empty strings and nil as values
  # @param [Hash|ActionController::Parameters] fields input which may contain blank values
  # @return [Hash] A hash without blanks
  def self.non_blank_fields(fields)
    fields.to_h.reject { |_, value| value.blank? }
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

  def parse_all_email_file_headers

    sender_domain_reputation_dispute_attachments.each do |sdr_attachment|
      if sdr_attachment.present?
        sdr_attachment.parse_email_content
      end
    end
  end

  def domain_name
    ascii_entry = SimpleIDN.to_ascii(self.sender_domain_entry)
    parser = Addressable::URI
    url = parser.escape(ascii_entry)
    uri = parser.parse(parser.parse(ascii_entry).scheme.nil? ? "http://#{url}" : url)
    domain = PublicSuffix.parse(uri.host, :ignore_private => true)

    full_domain = ""
    if domain.trd.present?
      full_domain += domain.trd + "."
    end
    full_domain += domain.domain

    SimpleIDN.to_unicode(full_domain)
  end

  def self.domain_name_of(entry)
    ascii_entry = SimpleIDN.to_ascii(entry)
    parser = Addressable::URI
    url = parser.escape(ascii_entry)
    uri = parser.parse(parser.parse(ascii_entry).scheme.nil? ? "http://#{url}" : url)
    domain = PublicSuffix.parse(uri.host, :ignore_private => true)

    full_domain = ""
    if domain.trd.present?
      full_domain += domain.trd + "."
    end
    full_domain += domain.domain

    return SimpleIDN.to_unicode(full_domain)

  end

  def get_and_save_beaker_data
    beaker_data = {}
    beaker_data[:request] = {}
    beaker_data[:response] = {}
    beaker_data[:response][:data] = {}

    begin

      smtp_envelope_params = { mail_from: self.sender_domain_entry, spf_results: {} }
      begin
        data_response = ::Beaker::Sdr.data_query('127.0.0.1', smtp_envelope_params: smtp_envelope_params).to_h
      rescue
        data_response = Beaker::Sdr.data_query('127.0.0.1', smtp_envelope_params: smtp_envelope_params).to_h
      end

      if data_response.present?
        data_response.keys.each do |key|
          begin
            data_response[key].to_json
          rescue
            data_response[key] = "could not translate encoded characters"
          end
        end
        begin
          data_response[:service_data].first[:data] = JSON.parse(data_response[:service_data].first[:data])
        rescue

        end
        beaker_data[:response][:data][self.sender_domain_entry] = data_response
      end

      beaker_data = beaker_data.to_json
    rescue => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      beaker_data = {:status => "failed", :message => "something went wrong trying to communicate with beaker and parsing data"}.to_json
    end

    self.beaker_info = beaker_data
    self.save
  end

  def get_email_meta_data
    response = {}
    if self.meta_data.present?
      begin
        meta_data = JSON.parse(self.meta_data).deep_symbolize_keys

        meta_cc = nil
        if meta_data[:ticket].present? && meta_data[:ticket][:cc].present?
          meta_cc = meta_data[:ticket][:cc]
        end

        if meta_data[:entry].present? && meta_data[:entry][:cc].present?
          meta_cc = meta_data[:entry][:cc]
        end

        if meta_cc.present?
          response[:cc] = meta_cc
        end
      rescue
        response = {}
      end

    end
    response
  end

  def is_assigned?
    (!self.user.blank? && self.user.email != 'vrt-incoming@sourcefire.com')
  end

  def customer_name
    customer.nil? ? "" : customer.name
  end

  def customer_email
    customer.nil? ? "" : customer.email
  end

  def customer_org
    if customer.nil?
      ""
    else
      customer.company.nil? ? "" : customer.company.name
    end
  end

  def compose_versioned_items
    versioned_items = [self]
    sender_domain_reputation_dispute_comments.includes(:versions).map{ |sdrdc| versioned_items << sdrdc }
    versioned_items
  end


  def self.export_xlsx(search_params, current_user)
    search_params = JSON.parse(search_params)
    disputes = robust_search(search_params['search_type'],
                                      search_name: search_params['search_name'],
                                      params: search_params['search_conditions'],
                                      user: current_user)
    if search_params['selected_cases'].present? && search_params['selected_cases'].length > 0
      disputes = disputes.where(id: search_params['selected_cases'])
    end

    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    EXPORT_FIELD_NAMES.values.each_with_index  do |field_name, col_index|
      worksheet.add_cell(0, col_index, field_name)
      worksheet.sheet_data[0][col_index].change_font_bold(true)
    end

    disputes.each_with_index do |sdr_dispute, row_index|
      EXPORT_FIELD_NAMES.keys.each_with_index do |field_name, col_index|
        cell_data =
          case field_name
          when 'platform'
            sdr_dispute.platform&.public_name
          when 'user_id'
            sdr_dispute.user&.cvs_username
          when 'created_at'
            sdr_dispute.created_at.utc.iso8601
          when 'customer_name'
            sdr_dispute.customer&.name
          when 'company_name'
            sdr_dispute&.customer&.company&.name
          when 'customer_email'
            sdr_dispute&.customer&.email
          when 'domain_name'
            sdr_dispute.domain_name
          when 'source'
            sdr_dispute.source || 'Internal'
          else
            sdr_dispute.attributes[field_name]
          end

        worksheet.add_cell(row_index + 1, col_index, cell_data)
      end
    end
    workbook
  end

  def self.assemble_initial_email(dispute, payload)
    email_subject = "SDR Entry: #{payload[:sender_domain_entry]}"
    email_body = assemble_email_body(dispute.created_at, payload)

    new_email = DisputeEmail.new
    new_email.body = email_body
    new_email.from = payload[:customer_email]
    new_email.sender_domain_reputation_dispute_id = dispute.id
    new_email.status = 'unread'
    new_email.to = "sdr_disputes_#{dispute.id}@dispute.talosintelligence.com"
    new_email.subject = email_subject
    new_email.save!
  end

  def self.assemble_email_body(dispute_created_at, payload)
    contents = "____________________________________________________________" + "\n"
    contents += "User-entered Information:" + "\n"
    contents += "____________________________________________________________" + "\n"
    contents += "Time: #{Time.now.to_formatted_s(:long)}" + "\n"
    contents += "Name: #{payload[:customer_name]}" + "\n"
    contents += "E-mail: #{payload[:customer_email]}" + "\n\n"
    contents += "Sender Domain Entry: #{payload[:sender_domain_entry]}" + "\n"
    contents += "Suggested Dispostion: #{payload[:suggested_disposition]}" + "\n"
    contents += "Details:" + "\n"
    contents += payload[:summary_description] || ''
    contents
  end
end
