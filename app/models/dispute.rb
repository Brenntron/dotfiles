class Dispute < ApplicationRecord
  has_many :dispute_comments
  has_many :dispute_emails

  def self.process_bridge_payload(message_payload)

    new_dispute = Dispute.new

    new_dispute.customer_name = message_payload["payload"]["name"]
    new_dispute.source_ip_address = message_payload["payload"]["user_ip"]
    new_dispute.customer_email = message_payload["payload"]["email"]
    new_dispute.org_domain = message_payload["payload"]["domain"]
    new_dispute.case_opened_at = Time.now
    new_dispute.subject = message_payload["payload"]["subject"]
    new_dispute.description = message_payload["payload"]["email_body"]
    new_dispute.problem_summary = message_payload["payload"]["problem"]
    new_dispute.ticket_source_key = message_payload["source_key"]
    new_dispute.ticket_source = "talos-intelligence"
    new_dispute.ticket_source_type = message_payload["source_type"]
    new_dispute.save

    new_entries_ips = message_payload["payload"]["investigate_ips"]
    new_entries_urls = message_payload["payload"]["investigate_urls"]

    new_entries_ips.each do |entry|
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.
    end

    new_entries_urls.each do |entry|

    end


    #change this
    return_message = {
      "envelope":
          {
              "channel": "fp-event",
              "addressee": "talos-intelligence",
              "sender": "analyst-console"
          },
      "message": {"source_key":params["source_key"],"ac_status":"CREATE_ACK"}
    }
  end
end
