class Dispute < ApplicationRecord
  has_many :dispute_comments
  has_many :dispute_emails

  def self.process_bridge_payload(message_payload)

    #change this
    return_message = {
      "envelope":
          {
              "channel": "fp-event",
              "addressee": "snort-org",
              "sender": "analyst-console"
          },
      "message": {"source_key":params["source_key"],"ac_status":"CREATE_ACK"}
    }
  end
end
