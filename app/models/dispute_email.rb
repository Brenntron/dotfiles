class DisputeEmail < ApplicationRecord
  belongs_to :dispute

  UNREAD   = "unread"
  READ     = "read"
  REPLIED  = "replied"

  REFERENCE_TEMPLATE = "ref-CASEID-anco"

  def self.process_bridge_payload(message_payload, xmlrpc, user)

    #check envelope for case validity
    case_id = find_case_number_in_email(message_payload)

    if case_id.blank?
      #create email to instruct user to use TI form and send to bridge
      return
    end

    new_email = DisputeEmail.new
    new_email.dispute_id = case_id
    new_email.email_headers = message_payload["payload"]["headers"]
    new_email.from = message_payload["payload"]["headers"]
    new_email.to = message_payload["payload"]["to"]
    new_email.subject = message_payload["payload"]["subject"]
    new_email.body = message_payload["payload"]["to"]
    new_email.status = UNREAD
    new_email.save

    if message_payload["attachments"].present?
      message_payload["attachments"].each do |email_attachment|
        DisputeEmailAttachment.build_and_push_to_bugzilla(xmlrpc, email_attachment, user, new_email)
      end
    end


    #change this
    return_message = {
        "envelope":
            {
                "channel": "email-acknowledge",
                "addressee": "talos-intelligence",
                "sender": "analyst-console"
            },
        "message": {"source_key":params[:source_key],"ac_status":"CREATE_ACK"}
    }

    return_message
  end

  ## FORMAT FOR AN EXTERNAL FACING CASE NUMBER IS:  ref-[dispute#id]-anco   example: ref-325302-anco wher 325302 is the ID of a record in disputes table
  def self.find_case_number_in_email(message_payload)
    email_address = message_payload['to']
    email_body = message_payload['text']

    if (email_address =~ /ref\-[0-9]+\-anco/) != nil
      case_id = email_address.scan( /ref\-([0-9]+)\-anco/ ).last.first
      return case_id
    end

    if (email_body =~ /ref\-[0-9]+\-anco/) != nil
      case_id = email_body.scan( /ref\-([0-9]+)\-anco/ ).last.first
      return case_id
    end

    return nil

  end

  def self.create_email_and_send(params)
    new_email = DisputeEmail.new
    new_email.from = generate_case_email_address(params[:dispute_id])
    new_email.to = ""
    new_email.subject = ""
    new_email.body = ""
    new_email.status = ""
    new_email.save




  end

end
