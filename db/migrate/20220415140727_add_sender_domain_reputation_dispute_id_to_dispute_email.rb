class AddSenderDomainReputationDisputeIdToDisputeEmail < ActiveRecord::Migration[5.2]
  def change
    add_column :dispute_emails, :sender_domain_reputation_dispute_id, :integer
  end
end
