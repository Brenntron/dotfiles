class AmpFalsePositive < ApplicationRecord
  belongs_to :file_reputation_ticket
  delegate :customer, :customer_id, to: :file_reputation_ticket, allow_nil: true

  def self.process_bridge_payload(message_payload)
    #what ever is coming in from the bridge should start here and end up eventually in create_file_rep_ticket
    user = User.where(cvs_username:"vrtincom").first    begin
                                                          ActiveRecord::Base.transaction do
                                                            create_file_rep_ticket(message_payload)
                                                          end
                                                        rescue Exception = e
                                                          raise("there was an error: #{e.message}")
                                                        end
  end

  def self.create_file_rep_ticket(params)
    #   use this method to create the File reputation ticket for this amp FP when needed
    #   get Customer
    # c = Customer.where(email: params[email]).first
    #   Create ReputationFile
    # repfile = ReputationFile.create(bugzilla_attachment_id: prams["bugzilla_attachment_id"],
    #                                 sha256: params["sha256"],
    #                                 file_path: params["file_path"],
    #                                 file_name:["file_name"])
    #   Create FileReputationTicket
    # file_ticket = FileReputationTicket.create(customer: c,
    #                                           status: params["status"],
    #                                           source: params["source"],
    #                                           description: params["description"],
    #                                           reputation_file: rep_file )
    #   Create AmpFalsePositive
    # ampFP = AmpFalsePositive.create(sr_id: params["parent_ticket_id"],
    #                                 payload: params["payload"],
    #                                 file_reputation_ticket: file_ticket)
    #
  end




end