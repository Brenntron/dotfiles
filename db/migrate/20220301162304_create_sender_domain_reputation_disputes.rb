class CreateSenderDomainReputationDisputes < ActiveRecord::Migration[5.2]
  def change
    create_table :sender_domain_reputation_disputes do |t|
      t.integer     :platform_id
      t.string      :platform_version
      t.text        :sender_domain_entry
      t.integer     :user_id
      t.string      :source
      t.string      :suggested_disposition
      t.string      :status
      t.string      :resolution
      t.string      :resolution_comment
      t.integer     :customer_id
      t.integer     :ticket_source_key
      t.string      :submitter_type
      t.mediumtext  :bridge_packet
      t.mediumtext  :meta_data
      t.text        :description
      t.datetime    :case_assigned_at
      t.datetime    :case_closed_at
      t.timestamps
    end
  end
end
