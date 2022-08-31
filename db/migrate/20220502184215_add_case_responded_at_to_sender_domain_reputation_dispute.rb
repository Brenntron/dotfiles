class AddCaseRespondedAtToSenderDomainReputationDispute < ActiveRecord::Migration[5.2]
  def change
    add_column :sender_domain_reputation_disputes, :case_responded_at, :datetime
  end
end
