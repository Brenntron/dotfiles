class CreateSenderDomainReputationEmailTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :sender_domain_reputation_email_templates do |t|
      t.string     :template_name
      t.text       :description
      t.text       :body
      t.timestamps
    end
  end
end
