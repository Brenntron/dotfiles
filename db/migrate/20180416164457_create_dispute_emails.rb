class CreateDisputeEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_emails do |t|
      t.integer      :dispute_id
      t.text         :email_headers
      t.string       :from
      t.text         :to
      t.text         :subject
      t.text         :body
      t.string       :status
      t.timestamps
    end
  end
end
