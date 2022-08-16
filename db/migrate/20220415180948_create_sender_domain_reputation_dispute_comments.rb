class CreateSenderDomainReputationDisputeComments < ActiveRecord::Migration[5.2]
  def change
    create_table :sender_domain_reputation_dispute_comments do |t|
      t.integer    :sender_domain_reputation_dispute_id
      t.integer    :user_id
      t.text       :comment
      t.timestamps
    end
  end
end
