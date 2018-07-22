class DisputeEmail < ApplicationRecord
  belongs_to :dispute
  has_many :dispute_email_attachments

  EMAIL_DOMAIN = "email.talosintelligence.com"
  NOREPLY      = "noreply"

  UNREAD   = "unread"
  READ     = "read"
  REPLIED  = "replied"
  SENT     = "sent"

  REFERENCE_TEMPLATE = "ref-CASEID-anco"

  def self.process_bridge_payload(message_payload)

    xmlrpc = message_payload[:bugzilla_session]
    user = message_payload[:current_user] 

    #check envelope for case validity
    case_id = find_case_number_in_email(message_payload["payload"])

    if case_id.blank?
      #create email to instruct user to use TI form and send to bridge
      return_message = {}

      bad_email_args = {}
      bad_email_args[:to] = message_payload["payload"]["from"]
      bad_email_args[:from] = "#{NOREPLY}@#{EMAIL_DOMAIN}"
      bad_email_args[:subject] = bad_gateway_subject
      bad_email_args[:body] = bad_gateway_body

      attachments_to_mail = []
      conn = ::Bridge::SendEmailEvent.new(addressee: 'talos-intelligence', source_authority: 'talos-intelligence')
      conn.post(bad_email_args, attachments_to_mail)

      #TODO: this is in a thread now, so send a bridge event for email acknowledge

      #return {
      #    "envelope":
      #        {
      #            "channel": "email-acknowledge",
      #            "addressee": "talos-intelligence",
      #            "sender": "analyst-console"
      #        },
      #    "message": {"source_key":message_payload[:source_key],"ac_status":"CREATE_ACK"}
      #}
    end

    new_email = DisputeEmail.new
    new_email.dispute_id = case_id
    new_email.email_headers = message_payload["payload"]["headers"]
    #Need to clean from value, can show up in form of:
    #\"Chris LaClair (claclair)\" <claclair@cisco.com>   which as an absolute value, is not a valid email address
    new_email.from = message_payload["payload"]["from"]
    new_email.to = message_payload["payload"]["to"]
    new_email.subject = message_payload["payload"]["subject"]
    new_email.body = message_payload["payload"]["text"]
    new_email.status = UNREAD
    new_email.save

    if message_payload["attachments"].present?
      message_payload["attachments"].each do |email_attachment|
        DisputeEmailAttachment.build_and_push_to_bugzilla(xmlrpc, email_attachment, user, new_email)
      end
    end


    #TODO: this is in a thread now, so send a bridge event for email acknowledge

    #change this
    #return_message = {
    #    "envelope":
    #        {
    #            "channel": "email-acknowledge",
    #            "addressee": "talos-intelligence",
    #            "sender": "analyst-console"
    #        },
    #    "message": {"source_key":message_payload[:source_key],"ac_status":"CREATE_ACK"}
    #}


  end

  ## FORMAT FOR AN EXTERNAL FACING CASE NUMBER IS:  ref-[dispute#id]-anco   example: ref-325302-anco wher 325302 is the ID of a record in disputes table
  def self.find_case_number_in_email(message_payload)

    email_address = message_payload['to']
    email_body = message_payload['text']

    email_case = ""
    body_case = ""
    if (email_address =~ /[0-9]+/) != nil
      email_case = email_address.scan( /([0-9]+)/ ).last.first.to_i
    end

    if (email_body =~ /ref\-[0-9]+\-anco/) != nil
      body_case = email_body.scan( /ref\-([0-9]+)\-anco/ ).last.first.to_i
    end

    if email_case == body_case
      return email_case
    end

    if email_case != body_case
      #### figure this out later
      #### thinking possibly create a new dispute with a 'suggested' related case
      if email_case.present?
        return email_case
      elsif body_case.present?
        return body_case
      else
        return nil
      end

    end

    return nil

  end

  def self.create_email_and_send(params, xmlrpc, user)
    new_email = DisputeEmail.new
    new_email.dispute_id = params[:dispute_id]
    new_email.from = user.email
    new_email.to = params[:to]
    new_email.subject = params[:subject]
    new_email.body = append_case_number(params[:body], params[:dispute_id])
    new_email.status = SENT
    new_email.email_sent_at = Time.now
    new_email.save

    attachments_to_mail = []

    if params[:attachments].present?
      params[:attachments].each do |key, attachment|

        payload = {}
        payload[:file_name] = attachment.filename
        payload[:file_content] = attachment.tempfile
        payload[:content_type] = attachment.type
        new_local_attachment = DisputeEmailAttachment.build_and_push_to_bugzilla(xmlrpc, payload, user, new_email, false)
        s3_file_path = new_local_attachment.push_to_aws(attachment)
        new_attachment = {}
        new_attachment[:file_name] = attachment.filename
        new_attachment[:file_url] = new_local_attachment.s3_url(s3_file_path)
        attachments_to_mail << new_attachment
      end
    end

    email_args = {}
    email_args[:to] = new_email.to
    email_args[:from] = generate_case_email_address(params[:dispute_id])
    email_args[:subject] = new_email.subject
    email_args[:body] = new_email.body
    email_args[:dispute_email_id] = new_email.id

    new_email.reload

    conn = ::Bridge::SendEmailEvent.new(addressee: 'talos-intelligence')
    conn.post(email_args, attachments_to_mail)

  end

  def self.generate_case_email_address(dispute_id)
    email_user = "rep_disputes_#{dispute_id}@#{EMAIL_DOMAIN}"

    email_user
  end

  def self.append_case_number(body, case_number)
    new_body = body
    body_case = nil
    if (body =~ /ref\-[0-9]+\-anco/) != nil
      body_case = body.scan( /ref\-([0-9]+)\-anco/ ).last.first.to_i
    end

    if body_case.nil?
      new_body += "\n\n"
      new_body += "-------------------------------------------------------------------------------------------------\n"
      new_body += "Please Do Not Remove This Reference Number.  Keep This Reference Number In The Email Chain:\n"
      new_body += "#{REFERENCE_TEMPLATE.gsub('CASEID', case_number.to_s)}\n"
      new_body += "-------------------------------------------------------------------------------------------------\n"
    end

    if body_case != case_number
      new_body.gsub(body_case.to_s, case_number.to_s)
    end

    return new_body

  end


  ## AUTO EMAIL MANAGEMENT

  def self.bad_gateway_subject
    "THINGS"
  end

  def self.bad_gateway_body
    <<-BADGATEWAY

      THIS IS THE BODY OF A BAD GATEWAY EMAIL THAT INSTRUCTS HOW TO USE TALOS INTELLIGENCE TO START A NEW CASE

    BADGATEWAY
  end




end
