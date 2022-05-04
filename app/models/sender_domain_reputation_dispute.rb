class SenderDomainReputationDispute < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at, :user_id]

  belongs_to :customer, optional: true
  belongs_to :user, optional:true

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

  RESOLUTION_DUPLICATE = "DUPLICATE"

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

      if message_payload["attachments"].present?
        message_payload["attachments"].each do |dispute_attachment|
          SenderDomainReputationDisputeAttachment.build_and_push_to_bugzilla(bugzilla_rest_session, dispute_attachment, user, new_dispute)
        end
        new_dispute.reload
      end

      if message_payload["attachments"].present? && message_payload["attachments"].size != new_dispute.sender_domain_reputation_dispute_attachments.size
        raise "attachments failed to save"
      end

      if new_dispute.sender_domain_reputation_dispute_attachments.present?
        new_dispute.parse_all_email_file_headers(bugzilla_rest_session)
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
    end


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
      attachment.retrieve_beaker_data_and_save
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
      conn = ::Bridge::SdrDisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: self.ticket_source_key, ac_id: self.id)
      conn.post(return_payload)
    rescue
      conn = Bridge::SdrDisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: self.ticket_source_key, ac_id: self.id)
      conn.post(return_payload)
    end

  end


  def send_failed_ack(source_key)

    conn = ::Bridge::SdrDisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: source_key)
    conn.post
  end

  def parse_all_email_file_headers(bugzilla_rest_session)

    bug_proxy = bugzilla_rest_session.build_bug(id: self.id)

    bug_attachments = bug_proxy.attachments

    bug_attachments.each do |bug_attachment|
      sdr_attachment = sender_domain_reputation_dispute_attachments.where(:id => bug_attachment.id).first
      if sdr_attachment.present?
        sdr_attachment.parse_email_content(bug_attachment)
      end
    end


  end

  def domain_name

    parser = URI::Parser.new
    url = parser.escape(self.sender_domain_entry)
    uri = parser.parse(parser.parse(self.sender_domain_entry).scheme.nil? ? "http://#{url}" : url)
    domain = PublicSuffix.parse(uri.host, :ignore_private => true)

    full_domain = ""
    if domain.trd.present?
      full_domain += domain.trd + "."
    end
    full_domain += domain.domain

    return full_domain

  end

  def get_and_save_beaker_data
    beaker_data = {}
    beaker_data[:request] = {}
    beaker_data[:response] = {}
    beaker_data[:response][:data] = {}

    mail_data_params = {}
    mail_data_params[:dkim_disp] = [{}]
    mail_data_params[:dmarc_disp] = {}
    mail_data_params[:email_list] = {}

    begin

      mail_data_params[:from_hdr] = [{"addr" => self.sender_domain_entry}]
      data_response = Beaker::Sdr.data_query('127.0.0.1', :mail_data_params => mail_data_params).to_h
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

end
