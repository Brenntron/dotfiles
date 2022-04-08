class SenderDomainReputationDispute < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at, :user_id]

  belongs_to :customer, optional: true
  belongs_to :user, optional:true
  belongs_to :platform, optional:true

  has_many :sender_domain_reputation_dispute_attachments

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  validates_length_of :resolution_comment, maximum: 2000, allow_blank: true

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
      new_dispute.meta_data = message_payload[:payload][:meta_data] if message_payload[:payload][:meta_data].present?
      new_dispute.user_id = user.id
      new_dispute.sender_domain_entry = message_payload[:payload][:sender_domain_entry]
      new_dispute.status = STATUS_NEW

      new_dispute.platform_id = platform.id
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

      #TODO: DO DUPLICATE CHECKING HERE
      #check_for_duplicate = FileReputationDispute.where(sha256_hash: message_payload[:payload][:sha256]).where.not(status: FileReputationDispute::STATUS_RESOLVED)
      #if check_for_duplicate.any?
        #auto_resolve_on_duplicate(new_dispute)
        #is_duplicate = true
      #else
      new_dispute.save
      #end

      if message_payload["attachments"].present?
        message_payload["attachments"].each do |dispute_attachment|
          SenderDomainReputationDisputeAttachment.build_and_push_to_bugzilla(bugzilla_rest_session, dispute_attachment, user, new_dispute)
        end
      end

      new_dispute.send_created_ack
    rescue => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      new_dispute.send_failed_ack(message_payload[:source_key])
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

    conn = ::Bridge::SdrDisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: self.ticket_source_key, ac_id: self.id)
    conn.post(return_payload)
  end


  def send_failed_ack(source_key)

    conn = ::Bridge::SdrDisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: source_key)
    conn.post
  end

  def return_dispute
    update!(user_id: User.vrtincoming.id, status: STATUS_NEW)
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

    SenderDomainReputationDispute.transaction do
      disputes = SenderDomainReputationDispute.where(id: dispute_ids)
      disputes_ary = disputes.to_a

      disputes.update_all(user_id: user_id, status: STATUS_ASSIGNED)
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
    # when 'advanced'
    #   advanced_search(params, search_name: search_name, user: user)
    # when 'named'
    #   named_search(search_name, user: user)
    # when 'standard'
    #   standard_search(search_name, user: user)
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
end
