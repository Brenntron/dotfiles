class CreateDisputes < ActiveRecord::Migration[5.1]
  def change
    create_table :disputes do |t|
      t.integer      :case_number
      t.string       :case_guid
      t.string       :customer_name
      t.string       :customer_email
      t.string       :customer_phone
      t.string       :customer_company_name
      t.string       :org_domain
      t.datetime     :case_opened_at
      t.datetime     :case_closed_at
      t.datetime     :case_accepted_at
      t.datetime     :case_resolved_at
      t.string       :status
      t.string       :resolution
      t.string       :priority
      t.text         :subject
      t.text         :description
      t.integer      :assigned_to
      t.string       :source_ip_address
      t.text         :problem_summary
      t.text         :research_notes
      t.string       :channel
      t.timestamps
    end
  end
end
